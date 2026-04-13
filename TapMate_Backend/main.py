# tapmate/backend/main.py

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
import yt_dlp
import os
import uuid
import re
import json
import shutil
import urllib.parse
import urllib.request
from pydantic import BaseModel
from typing import Optional

app = FastAPI(title="TapMate Downloader API")

# CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Downloads folder
DOWNLOAD_DIR = "downloads"
os.makedirs(DOWNLOAD_DIR, exist_ok=True)

class DownloadRequest(BaseModel):
    url: str
    quality: Optional[str] = "best"
    cookie_header: Optional[str] = None


def _normalize_input_url(url: str) -> str:
    normalized = (url or '').strip()
    if not normalized:
        return normalized

    # Add scheme if user pastes without protocol.
    if not re.match(r'^https?://', normalized, flags=re.IGNORECASE):
        normalized = f'https://{normalized}'

    parsed = urllib.parse.urlparse(normalized)
    host = parsed.netloc.lower()

    # Resolve short TikTok links to canonical URL for better extractor stability.
    if 'vm.tiktok.com' in host or 'vt.tiktok.com' in host:
        try:
            request = urllib.request.Request(
                normalized,
                method='GET',
                headers={
                    'User-Agent': (
                        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
                        'AppleWebKit/537.36 (KHTML, like Gecko) '
                        'Chrome/124.0.0.0 Safari/537.36'
                    ),
                    'Referer': 'https://www.tiktok.com/',
                },
            )
            opener = urllib.request.build_opener(urllib.request.HTTPRedirectHandler())
            with opener.open(request, timeout=20) as response:
                resolved = response.geturl()
                if resolved:
                    normalized = resolved
        except Exception:
            # Keep original URL if resolving fails.
            pass

    # Remove common tracking params.
    parsed = urllib.parse.urlparse(normalized)
    query = urllib.parse.parse_qs(parsed.query)
    for key in ['utm_source', 'utm_medium', 'utm_campaign', 'share_app_id', 'share_item_id']:
        query.pop(key, None)
    clean_query = urllib.parse.urlencode(query, doseq=True)
    normalized = urllib.parse.urlunparse(
        (parsed.scheme, parsed.netloc, parsed.path, parsed.params, clean_query, '')
    )

    return normalized


def _sanitize_filename(name: str) -> str:
    clean = re.sub(r'[^\w\s-]', '', name).strip()
    clean = re.sub(r'\s+', '_', clean)
    return clean or 'video'


def _is_instagram_url(url: str) -> bool:
    lower = (url or '').lower()
    return 'instagram.com' in lower or 'instagr.am' in lower


def _trim_cookie_header(cookie_header: Optional[str]) -> Optional[str]:
    if not cookie_header:
        return None
    # Keep header size bounded to avoid malformed oversized requests.
    trimmed = cookie_header.strip()
    if not trimmed:
        return None
    return trimmed[:8000]


def _get_facebook_video_url(url: str) -> dict:
    """
    Extract Facebook video URL using direct approach.
    Returns a dict with title, video_url, and error if any.
    """
    try:
        headers = {
            'User-Agent': (
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
            ),
            'Referer': 'https://www.facebook.com/',
            'Accept-Language': 'en-US,en;q=0.9',
        }

        request = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(request, timeout=20) as response:
            html_content = response.read().decode('utf-8', errors='ignore')

            # Try to extract video URL from HTML
            import re
            patterns = [
                r'"video_links":\[\{"url":"([^"]+)"',
                r'"playable_url":"([^"]+)"',
                r'"src":"(https://[^"]+video[^"]+)"',
                r'href="(https://www\.facebook\.com/watch/?\?v=\d+)"',
            ]

            for pattern in patterns:
                match = re.search(pattern, html_content)
                if match:
                    video_url = match.group(1)
                    video_url = video_url.replace('\\/', '/')
                    return {'video_url': video_url, 'error': None}

        return {'video_url': None, 'error': 'Could not extract video URL from Facebook page'}
    except Exception as e:
        return {'video_url': None, 'error': str(e)}


# 🔥 FIXED: Improved TikTok download function
def _download_tiktok_via_tikwm(url: str, task_id: str):
    """Download TikTok video using TikWM API - IMPROVED VERSION"""

    # Clean URL first
    url = url.strip()

    # Resolve short TikTok links
    if 'vm.tiktok.com' in url or 'vt.tiktok.com' in url:
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=10) as response:
                url = response.geturl()
        except:
            pass

    payload = urllib.parse.urlencode({'url': url, 'hd': '1'}).encode('utf-8')
    headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/json',
        'Origin': 'https://tikwm.com',
        'Referer': 'https://tikwm.com/',
    }

    # Try multiple API endpoints
    api_urls = [
        'https://tikwm.com/api/',
        'https://www.tikwm.com/api/',
    ]

    last_error = None

    for api_url in api_urls:
        try:
            request = urllib.request.Request(api_url, data=payload, headers=headers)
            with urllib.request.urlopen(request, timeout=30) as response:
                body = response.read().decode('utf-8', errors='ignore')
                parsed = json.loads(body)

                if parsed.get('code') == 0:
                    data = parsed.get('data') or {}
                    video_url = data.get('hdplay') or data.get('play') or data.get('wmplay')
                    if video_url:
                        title = data.get('title') or f'tiktok_{task_id}'
                        safe_title = _sanitize_filename(title)[:80]
                        filename = f"{safe_title}_{task_id}.mp4"
                        filepath = os.path.join(DOWNLOAD_DIR, filename)

                        video_req = urllib.request.Request(
                            video_url,
                            headers={
                                'User-Agent': headers['User-Agent'],
                                'Referer': 'https://www.tiktok.com/',
                            },
                        )

                        with urllib.request.urlopen(video_req, timeout=60) as source, open(filepath, 'wb') as dest:
                            shutil.copyfileobj(source, dest)

                        return {
                            'title': title,
                            'filename': filename,
                            'filepath': filepath,
                        }
        except Exception as e:
            last_error = str(e)
            continue

    raise Exception(f"TikTok download failed: {last_error}")


@app.get("/")
async def root():
    return {"message": "TapMate Downloader API", "status": "running"}

@app.post("/api/download")
async def download_video(request: DownloadRequest):
    """
    Download video from any platform
    """
    task_id = str(uuid.uuid4())
    output_template = os.path.join(DOWNLOAD_DIR, f"%(title)s_{task_id}.%(ext)s")

    normalized_url = _normalize_input_url(request.url)
    if not normalized_url:
        raise HTTPException(status_code=400, detail='Invalid URL')

    is_tiktok = 'tiktok.com' in normalized_url.lower()
    is_facebook = 'facebook.com' in normalized_url.lower() or 'fb.watch' in normalized_url.lower()
    is_instagram = _is_instagram_url(normalized_url)
    cookie_header = _trim_cookie_header(request.cookie_header)

    referer = 'https://www.tiktok.com/'
    if is_facebook:
        referer = 'https://www.facebook.com/'
    elif is_instagram:
        referer = 'https://www.instagram.com/'

    ydl_opts = {
        'format': request.quality if request.quality else 'best',
        'outtmpl': output_template,
        'quiet': True,
        'noplaylist': True,
        'retries': 5,
        'fragment_retries': 5,
        'extractor_retries': 3,
        'socket_timeout': 30,
        'http_headers': {
            'Referer': referer,
            'User-Agent': (
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
            ),
        },
    }

    if is_instagram:
        ydl_opts.update({
            'impersonate': 'chrome',
            'extractor_args': {
                'instagram': {
                    'api_version': ['v1'],
                },
            },
        })

    if is_instagram and cookie_header:
        ydl_opts['http_headers']['Cookie'] = cookie_header

    if is_tiktok:
        ydl_opts.update({
            'impersonate': 'chrome',
            'extractor_args': {
                'tiktok': {
                    'api_hostname': ['api22-normal-c-useast2a.tiktokv.com'],
                },
            },
        })

    if is_facebook:
        ydl_opts.update({
            'no_warnings': True,
            'quiet': True,
            'extract_flat': False,
        })

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(normalized_url, download=True)
            filename = ydl.prepare_filename(info)

            return {
                'success': True,
                'task_id': task_id,
                'title': info.get('title', ''),
                'filename': os.path.basename(filename),
                'filepath': filename
            }

    except Exception as e:
        error_msg = str(e)

        if is_tiktok:
            try:
                fallback = _download_tiktok_via_tikwm(normalized_url, task_id)
                return {
                    'success': True,
                    'task_id': task_id,
                    'title': fallback['title'],
                    'filename': fallback['filename'],
                    'filepath': fallback['filepath'],
                    'source': 'tikwm_fallback',
                }
            except Exception as fallback_error:
                raise HTTPException(
                    status_code=400,
                    detail=f"TikTok download failed. yt-dlp: {str(e)} | fallback: {str(fallback_error)}",
                )

        if is_facebook:
            # Try direct Facebook video extraction as fallback
            try:
                fb_result = _get_facebook_video_url(normalized_url)
                if fb_result['video_url']:
                    # Download using the extracted URL
                    try:
                        filename = f"facebook_video_{task_id}.mp4"
                        filepath = os.path.join(DOWNLOAD_DIR, filename)

                        video_request = urllib.request.Request(
                            fb_result['video_url'],
                            headers={
                                'User-Agent': (
                                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                                    '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
                                ),
                                'Referer': 'https://www.facebook.com/',
                            },
                        )

                        with urllib.request.urlopen(video_request, timeout=60) as source, open(filepath, 'wb') as destination:
                            shutil.copyfileobj(source, destination)

                        return {
                            'success': True,
                            'task_id': task_id,
                            'title': 'Facebook Video',
                            'filename': filename,
                            'filepath': filepath,
                            'source': 'facebook_fallback',
                        }
                    except Exception as download_error:
                        raise HTTPException(
                            status_code=400,
                            detail=f"Failed to download extracted Facebook video: {str(download_error)}"
                        )
                else:
                    raise HTTPException(
                        status_code=400,
                        detail=f"Facebook: {fb_result['error']}"
                    )
            except HTTPException as http_error:
                raise http_error
            except Exception as fallback_error:
                raise HTTPException(
                    status_code=400,
                    detail=f"Facebook download failed. yt-dlp: {str(e)} | fallback: {str(fallback_error)}",
                )

        if is_instagram and not cookie_header:
            raise HTTPException(
                status_code=400,
                detail=(
                    f"{error_msg}. Instagram may require an authenticated cookie header. "
                    "Retry by sending cookie_header from an already logged-in Instagram browser session."
                ),
            )

        raise HTTPException(status_code=400, detail=error_msg)

@app.get("/api/file/{task_id}")
async def get_file(task_id: str):
    """Get downloaded file"""
    for filename in os.listdir(DOWNLOAD_DIR):
        if task_id in filename:
            file_path = os.path.join(DOWNLOAD_DIR, filename)
            return FileResponse(file_path, filename=filename)

    raise HTTPException(status_code=404, detail="File not found")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
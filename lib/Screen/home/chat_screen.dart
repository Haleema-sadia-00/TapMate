import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard ke liye

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Dummy chats
  final List<Map<String, dynamic>> chats = [
    {"name": "tech_guru", "msg": "Check this out", "time": "1h ago", "icon": Icons.computer, "online": true},
    {"name": "fitness_pro", "msg": "Gym 7pm?", "time": "3h ago", "icon": Icons.fitness_center, "online": false},
    {"name": "music_lover", "msg": "New playlist 🔥", "time": "1d ago", "icon": Icons.music_note, "online": false, "unread": 2},
    {"name": "travel_buddy", "msg": "Trip update", "time": "2d ago", "icon": Icons.flight, "online": false},
  ];

  String currentChatName = "";
  IconData currentChatIcon = Icons.person;
  Map<String, List<String>> chatMessages = {};

  void openChat(Map<String, dynamic> chat) {
    setState(() {
      currentChatName = chat['name'];
      currentChatIcon = chat['icon'];
      if (!chatMessages.containsKey(currentChatName)) {
        chatMessages[currentChatName] = [chat['msg']];
      }
    });
  }

  void goBackToChatList() {
    setState(() {
      currentChatName = "";
    });
  }

  void sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() {
      chatMessages[currentChatName]!.add(_messageController.text.trim());
      _messageController.clear();
    });
  }

  void deleteMessage(int index) {
    setState(() {
      chatMessages[currentChatName]!.removeAt(index);
    });
  }

  void copyMessage(int index) {
    Clipboard.setData(
      ClipboardData(text: chatMessages[currentChatName]![index]),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Message copied!")),
    );
  }

  // ================= UPDATED NAV ITEM =================
  Widget _buildNavItem(IconData icon, String label, bool isActive, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (label == "Home") {
          Navigator.pushReplacementNamed(context, '/home');
        } else if (label == "Discover") {
          Navigator.pushReplacementNamed(context, '/search');
        } else if (label == "Feed") {
          Navigator.pushReplacementNamed(context, '/feed');
        } else if (label == "Message") {
          Navigator.pushReplacementNamed(context, '/chat');
        } else if (label == "Profile") {
          Navigator.pushReplacementNamed(context, '/profile');
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFFA64D79) : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? const Color(0xFFA64D79) : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: Column(
            children: [
              // ================= HEADER =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3B1C32),
                      Color(0xFF6A1E55),
                      Color(0xFFA64D79),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B1C32).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // ✅ FIXED BACK BUTTON LOGIC
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () {
                        if (currentChatName.isNotEmpty) {
                          // If in chat detail, go back to chat list
                          goBackToChatList();
                        } else {
                          // If already in chat list, go to home
                          Navigator.pushReplacementNamed(context, '/home');
                        }
                      },
                    ),

                    if (currentChatName.isNotEmpty)
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(currentChatIcon, color: const Color(0xFF6A1E55)),
                      ),
                    if (currentChatName.isNotEmpty) const SizedBox(width: 10),
                    Text(
                      currentChatName.isEmpty ? "Chats" : currentChatName,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // ================= BODY =================
              Expanded(
                child: currentChatName.isEmpty ? buildChatList() : buildChatDetail(),
              ),

              // ================= BOTTOM NAVIGATION =================
              Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.home_rounded, 'Home', false, context),
                    _buildNavItem(Icons.explore_rounded, 'Discover', false, context),
                    _buildNavItem(Icons.feed_rounded, 'Feed', false, context),
                    _buildNavItem(Icons.message_rounded, 'Message', true, context),
                    _buildNavItem(Icons.person_rounded, 'Profile', false, context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildChatList() {
    List<Map<String, dynamic>> filteredChats = chats
        .where((chat) => chat['name']
        .toString()
        .toLowerCase()
        .contains(_searchController.text.toLowerCase()))
        .toList();

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF6A1E55)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {});
                    },
                    decoration: const InputDecoration(
                      hintText: "Search conversations...",
                      border: InputBorder.none,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),

        // Chat list
        Expanded(
          child: ListView(
            children: filteredChats.map((chat) {
              return GestureDetector(
                onTap: () => openChat(chat),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFA64D79), Color(0xFF6A1E55)],
                              ),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.white,
                              child: Icon(chat['icon'], color: const Color(0xFF6A1E55), size: 20),
                            ),
                          ),
                          if (chat['online'])
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(chat['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              chatMessages[chat['name']] != null
                                  ? chatMessages[chat['name']]!.last
                                  : chat['msg'],
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget buildChatDetail() {
    final messages = chatMessages[currentChatName]!;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onLongPress: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.content_copy),
                              title: const Text('Copy'),
                              onTap: () {
                                copyMessage(index);
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete),
                              title: const Text('Delete'),
                              onTap: () {
                                deleteMessage(index);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1E55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      messages[index],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Color(0xFFA64D79)),
                onPressed: sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
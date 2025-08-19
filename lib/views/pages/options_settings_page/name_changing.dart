import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:later/services/auth/user_services.dart';
import 'package:provider/provider.dart';

class NameChangingWidget extends StatefulWidget {
  const NameChangingWidget({super.key});

  @override
  State<NameChangingWidget> createState() => _NameChangingWidgetState();
}

class _NameChangingWidgetState extends State<NameChangingWidget> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;
  String? _error;

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a new name!')));
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final userService = Provider.of<UserService>(context, listen: false);
    final uid = userService.uid;
    if (uid == null) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in.')));
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': name,
      });

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name updated!')));
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update name.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: screenHeight * 0.68),
            child: Column(
              children: [
                Container(
                  width: screenWidth,
                  height: screenHeight * 0.18,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        bottom: 4,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                'Name',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Irina',
                                  color: Colors.black,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.05,
                                  vertical: 0,
                                ),
                                child: Text(
                                  'This is how you will be shown on Later, pick a name wisely so your friends know you by',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    fontFamily: 'Irina',
                                    color: Color.fromARGB(255, 94, 94, 94),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 60,
                        left: 8,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Image.asset(
                            'assets/images/icons/prof_page/go_back.png',
                            width: screenWidth * 0.11,
                            height: screenWidth * 0.11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Center(
                  child: Container(
                    width: screenWidth * 0.92,
                    height: 50,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.01,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          spreadRadius: 1,
                          blurRadius: 9,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: "Enter new name",
                        errorText: _error,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.001,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: screenWidth * 0.15,
            right: screenWidth * 0.15,
            bottom: screenHeight * 0.05,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    spreadRadius: 1,
                    blurRadius: 9,
                    offset: Offset(0, 4),
                  ),
                ],
                borderRadius: BorderRadius.circular(25),
              ),
              child: SizedBox(
                width: screenWidth * 0.45,
                height: screenHeight * 0.06,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 86, 201, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isSaving ? null : _saveName,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Save",
                          style: TextStyle(
                            fontSize: screenWidth * 0.065,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Irina',
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

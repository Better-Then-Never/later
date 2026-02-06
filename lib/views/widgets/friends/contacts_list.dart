import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:later/services/user_data_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:later/services/popup_notification_service.dart';
import 'package:provider/provider.dart';

class ContactsList extends StatelessWidget {
  final List<Contact> contacts;
  final String searchQuery;
  final bool isLoading;

  const ContactsList({
    super.key,
    required this.contacts,
    required this.searchQuery,
    required this.isLoading,
  });

  List<Contact> get _filteredContacts {
    if (searchQuery.isEmpty) return contacts;

    return contacts.where((contact) {
      final name = contact.displayName.toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();
  }

  String _generateProfileLink(String userId) {
    return 'https://later-da778.web.app/?userId=$userId';
  }

  Future<void> _sendInvite(BuildContext context, Contact contact) async {
    if (contact.phones.isEmpty) return;

    final userService = Provider.of<UserDataService>(context, listen: false);
    final userId = userService.currentLoggedInUid;

    String phoneNumber = contact.phones.first.number;
    phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (!phoneNumber.startsWith('+')) {
      phoneNumber = phoneNumber.replaceAll('+', '');
    }

    final profileLink = _generateProfileLink(userId);
    final message =
        "Hey! Join me on Later! Download it now and add me as a friend. \n$profileLink";

    final encodedMessage = Uri.encodeComponent(message);

    final smsUrl = Uri.parse('sms:$phoneNumber?body=$encodedMessage');

    try {
      if (await canLaunchUrl(smsUrl)) {
        await launchUrl(smsUrl);

        if (context.mounted) {
          PopupNotificationService.showSuccess(
            context: context,
            message: 'Invite sent to ${contact.displayName}!',
            position: NotificationPosition.bottom,
          );
        }
      } else {
        if (context.mounted) {
          PopupNotificationService.showError(
            context: context,
            message: 'Unable to open messaging app',
            position: NotificationPosition.bottom,
          );
        }
      }
    } catch (e) {
      print('Error sending invite: $e');
      if (context.mounted) {
        PopupNotificationService.showError(
          context: context,
          message: 'Failed to send invite',
          position: NotificationPosition.bottom,
        );
      }
    }
  }

  Widget _buildContactItem(BuildContext context, Contact contact) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Color(0xFFEAEAEA),
          backgroundImage: contact.photo != null
              ? MemoryImage(contact.photo!)
              : null,
          child: contact.photo == null
              ? Text(
                  contact.displayName.isNotEmpty
                      ? contact.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                )
              : null,
        ),
        title: Text(
          contact.displayName.isEmpty ? 'Unknown' : contact.displayName,
          style: TextStyle(
            fontFamily: 'Irina',
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        subtitle: contact.phones.isNotEmpty
            ? Text(
                contact.phones.first.number,
                style: TextStyle(
                  fontFamily: 'Irina',
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              )
            : null,
        trailing: GestureDetector(
          onTap: () => _sendInvite(context, contact),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 86, 201, 46),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/icons/prof_page/add_friend.png',
                  width: 20,
                  height: 20,
                  color: Colors.white,
                ),
                SizedBox(width: 6),
                Text(
                  'Invite',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Color.fromARGB(255, 33, 150, 243),
        ),
      );
    }

    if (_filteredContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/icons/prof_page/friend_search.png',
              width: 72,
              height: 72,
              color: Colors.black,
            ),
            SizedBox(height: 8),
            Text(
              searchQuery.isEmpty
                  ? 'No contacts found'
                  : 'No contacts match your search',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                fontFamily: 'Irina',
                color: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        top: screenHeight * 0.007,
        bottom: screenHeight * 0.12,
      ),
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        return _buildContactItem(context, _filteredContacts[index]);
      },
    );
  }
}

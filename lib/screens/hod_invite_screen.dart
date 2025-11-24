import 'package:flutter/material.dart';
import '../services/hod_invite_service.dart';
import '../config/hod_config.dart';
import '../widgets/glass_button.dart';

/// Screen for sending password reset links to HOD emails
/// Allows admin to invite HODs to set their passwords
class HodInviteScreen extends StatefulWidget {
  const HodInviteScreen({super.key});

  @override
  State<HodInviteScreen> createState() => _HodInviteScreenState();
}

class _HodInviteScreenState extends State<HodInviteScreen> {
  final _hodInviteService = HodInviteService();
  bool _isSending = false;
  Map<String, bool>? _sendResults;

  /// Send password reset link to a specific HOD email
  Future<void> _sendInviteToEmail(String email) async {
    setState(() {
      _isSending = true;
      _sendResults = null;
    });

    try {
      final success = await _hodInviteService.inviteHod(email);
      
      if (mounted) {
        setState(() {
          _sendResults = {email: success};
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Password reset link sent to $email'
                  : 'Failed to send invite to $email',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  /// Send password reset links to all HOD emails
  Future<void> _sendInviteToAll() async {
    setState(() {
      _isSending = true;
      _sendResults = null;
    });

    try {
      final results = await _hodInviteService.inviteAllHods();
      
      if (mounted) {
        setState(() {
          _sendResults = results;
        });
        
        final successCount = results.values.where((v) => v == true).length;
        final totalCount = results.length;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sent invites to $successCount out of $totalCount HOD emails',
            ),
            backgroundColor: successCount == totalCount ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const hodEmails = HodConfig.allowedHodEmails;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Invite HOD'),
        backgroundColor: Colors.blue[100],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Send Password Reset Links to HOD',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This will send a password reset link to the HOD email addresses. '
                      'HODs can click the link in their email to set their password and login.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // HOD emails list
            if (hodEmails.isEmpty)
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No HOD emails configured. Add HOD emails in lib/config/hod_config.dart',
                          style: TextStyle(color: Colors.orange[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Text(
                'Configured HOD Emails (${hodEmails.length}):',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              
              // List of HOD emails
              ...hodEmails.map((email) {
                final isSuccess = _sendResults?[email] == true;
                final isFailed = _sendResults?[email] == false;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isSuccess
                      ? Colors.green[50]
                      : isFailed
                          ? Colors.red[50]
                          : Colors.white,
                  child: ListTile(
                    leading: Icon(
                      isSuccess
                          ? Icons.check_circle
                          : isFailed
                              ? Icons.error
                              : Icons.email,
                      color: isSuccess
                          ? Colors.green[700]
                          : isFailed
                              ? Colors.red[700]
                              : Colors.blue[700],
                    ),
                    title: Text(
                      email,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSuccess
                            ? Colors.green[900]
                            : isFailed
                                ? Colors.red[900]
                                : Colors.black87,
                      ),
                    ),
                    subtitle: isSuccess
                        ? const Text('Invite sent successfully')
                        : isFailed
                            ? const Text('Failed to send invite')
                            : const Text('Click to send invite'),
                    trailing: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () => _sendInviteToEmail(email),
                            tooltip: 'Send invite',
                          ),
                    onTap: _isSending ? null : () => _sendInviteToEmail(email),
                  ),
                );
              }),
              
              const SizedBox(height: 24),
              
              // Send to all button
              _isSending
                  ? const Center(child: CircularProgressIndicator())
                  : GlassButton(
                      label: 'Send Invite to All HODs',
                      icon: Icons.send,
                      onPressed: _sendInviteToAll,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}


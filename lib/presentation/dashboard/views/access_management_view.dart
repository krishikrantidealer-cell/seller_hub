import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../logic/order/order_bloc.dart';

class PermissionMeta {
  final String key;
  final String label;
  final String group;

  const PermissionMeta(this.key, this.label, this.group);
}

const List<PermissionMeta> kAllSalesPermissions = [
  PermissionMeta('DASHBOARD_VIEW', 'View Sales Agent Dashboard', 'Dashboard'),
  PermissionMeta('CATALOG_VIEW', 'View Products, Categories & Collections', 'Catalog'),
  PermissionMeta('CATALOG_MANAGE', 'Create & Edit Products / Categories', 'Catalog'),
  PermissionMeta('USERS_SELLERS_VIEW', 'View Sellers Directory', 'Users & Directory'),
  PermissionMeta('USERS_CUSTOMERS_VIEW', 'View Customers & Profiles', 'Users & Directory'),
  PermissionMeta('USERS_CUSTOMERS_MANAGE', 'Create & Edit Customers', 'Users & Directory'),
  PermissionMeta('ORDERS_VIEW', 'View Orders & Tracking', 'Orders & Dispatch'),
  PermissionMeta('ORDERS_CREATE', 'Create Orders for Customers', 'Orders & Dispatch'),
  PermissionMeta('ORDERS_MANAGE', 'Confirm, Label, Pack & Cancel Orders', 'Orders & Dispatch'),
  PermissionMeta('MARKETING_VIEW', 'View Marketing Tab, Blogs & Banners', 'Marketing & Growth'),
  PermissionMeta('MARKETING_MANAGE', 'Launch Campaigns, Blogs, Banners & Collections', 'Marketing & Growth'),
  PermissionMeta('ENGAGEMENT_VIEW', 'View Engagement Tab, Reviews & Webhooks', 'Engagement & Telemetry'),
  PermissionMeta('ENGAGEMENT_MANAGE', 'Manage Engagement Campaigns & Moderate Reviews', 'Engagement & Telemetry'),
];

class AccessManagementView extends StatefulWidget {
  const AccessManagementView({super.key});

  @override
  State<AccessManagementView> createState() => _AccessManagementViewState();
}

class _AccessManagementViewState extends State<AccessManagementView> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _agents = const [];

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final api = context.read<OrderBloc>().apiClient;
      final res = await api.get(ApiEndpoints.adminSalesAgents, requiresAuth: true);
      final data = res['data'];
      final rawList = (data is Map ? data['agents'] : null) as List<dynamic>? ?? const [];
      if (mounted) {
        setState(() {
          _agents = rawList.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  String _generateRandomPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789@#!';
    final rnd = Random.secure();
    return List.generate(10, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  String _generateRandomEmail(String firstName) {
    final clean = firstName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final prefix = clean.isNotEmpty ? clean : 'sales';
    final num = 100 + Random.secure().nextInt(900);
    return '$prefix.$num@ebssales.in';
  }

  Future<void> _openCreateAgentDialog() async {
    final firstCtrl = TextEditingController();
    final lastCtrl = TextEditingController();
    final emailCtrl = TextEditingController(text: _generateRandomEmail('agent'));
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: _generateRandomPassword());
    String selectedRole = 'ROLE_SALES_AGENT';
    final selectedPerms = <String>{
      'DASHBOARD_VIEW',
      'USERS_CUSTOMERS_VIEW',
      'USERS_CUSTOMERS_MANAGE',
      'ORDERS_VIEW',
      'ORDERS_CREATE',
    };
    String? dialogError;
    bool submitting = false;

    final created = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final surface = isDark ? const Color(0xFF0F172A) : Colors.white;
          final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
          return Dialog(
            backgroundColor: surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.support_agent_rounded, color: Color(0xFF059669), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Create Sales Agent & Assign Access',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: submitting ? null : () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        dialogError!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: firstCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'First Name *',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: lastCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Last Name',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: emailCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Login Email *',
                                      isDense: true,
                                      border: const OutlineInputBorder(),
                                      suffixIcon: IconButton(
                                        tooltip: 'Generate random email',
                                        icon: const Icon(Icons.casino_outlined, size: 18),
                                        onPressed: () => setDialogState(() {
                                          emailCtrl.text = _generateRandomEmail(firstCtrl.text);
                                        }),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: phoneCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Phone (optional)',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: passCtrl,
                              decoration: InputDecoration(
                                labelText: 'Password (auto-generated if blank)',
                                isDense: true,
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  tooltip: 'Generate random password',
                                  icon: const Icon(Icons.refresh_rounded, size: 18),
                                  onPressed: () => setDialogState(() {
                                    passCtrl.text = _generateRandomPassword();
                                  }),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              initialValue: selectedRole,
                              decoration: const InputDecoration(
                                labelText: 'Staff Role *',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'ROLE_SALES_AGENT', child: Text('Sales Agent (ROLE_SALES_AGENT)')),
                                DropdownMenuItem(value: 'ROLE_MARKETING', child: Text('Marketing & Engagement (ROLE_MARKETING)')),
                              ],
                              onChanged: (val) {
                                if (val == null) return;
                                setDialogState(() {
                                  selectedRole = val;
                                  selectedPerms.clear();
                                  if (val == 'ROLE_MARKETING') {
                                    selectedPerms.addAll([
                                      'MARKETING_VIEW',
                                      'MARKETING_MANAGE',
                                      'ENGAGEMENT_VIEW',
                                      'ENGAGEMENT_MANAGE',
                                      'CATALOG_VIEW',
                                    ]);
                                  } else {
                                    selectedPerms.addAll([
                                      'DASHBOARD_VIEW',
                                      'USERS_CUSTOMERS_VIEW',
                                      'USERS_CUSTOMERS_MANAGE',
                                      'ORDERS_VIEW',
                                      'ORDERS_CREATE',
                                    ]);
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'ASSIGNED TABS & PERMISSIONS',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: border),
                              ),
                              child: Column(
                                children: kAllSalesPermissions.map((perm) {
                                  final checked = selectedPerms.contains(perm.key);
                                  return CheckboxListTile(
                                    dense: true,
                                    value: checked,
                                    activeColor: const Color(0xFF059669),
                                    title: Text(
                                      perm.label,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${perm.group} • ${perm.key}',
                                      style: GoogleFonts.jetBrainsMono(fontSize: 10),
                                    ),
                                    onChanged: (v) {
                                      setDialogState(() {
                                        if (v == true) {
                                          selectedPerms.add(perm.key);
                                        } else {
                                          selectedPerms.remove(perm.key);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: submitting ? null : () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: submitting
                              ? null
                              : () async {
                                  if (firstCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                                    setDialogState(() => dialogError = 'First name and email are required.');
                                    return;
                                  }
                                  setDialogState(() {
                                    submitting = true;
                                    dialogError = null;
                                  });
                                  try {
                                    final api = context.read<OrderBloc>().apiClient;
                                    final res = await api.post(
                                      ApiEndpoints.adminSalesAgents,
                                      body: {
                                        'firstName': firstCtrl.text.trim(),
                                        'lastName': lastCtrl.text.trim(),
                                        'email': emailCtrl.text.trim(),
                                        if (phoneCtrl.text.trim().isNotEmpty)
                                          'phoneNumber': phoneCtrl.text.trim(),
                                        if (passCtrl.text.trim().isNotEmpty)
                                          'password': passCtrl.text.trim(),
                                        'role': selectedRole,
                                        'permissions': selectedPerms.toList(),
                                      },
                                      requiresAuth: true,
                                    );
                                    if (ctx.mounted) {
                                      final data = res['data'];
                                      Navigator.of(ctx).pop(
                                        data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{},
                                      );
                                    }
                                  } on ApiException catch (e) {
                                    setDialogState(() {
                                      submitting = false;
                                      dialogError = e.message;
                                    });
                                  } catch (e) {
                                    setDialogState(() {
                                      submitting = false;
                                      dialogError = e.toString();
                                    });
                                  }
                                },
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(submitting ? 'Creating...' : 'Create Sales Agent'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (created != null && mounted) {
      await _loadAgents();
      if (!mounted) return;
      final genPass = created['generatedPassword']?.toString() ?? '';
      final email = created['email']?.toString() ?? '';
      if (genPass.isNotEmpty) {
        _showCredentialsDialog(email, genPass);
      }
    }
  }

  Future<void> _showCredentialsDialog(String email, String password) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Sales Agent Credentials',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share these credentials with the sales agent (password is shown once):'),
            const SizedBox(height: 12),
            SelectableText('Email: $email', style: GoogleFonts.jetBrainsMono(fontSize: 13)),
            const SizedBox(height: 6),
            SelectableText('Password: $password', style: GoogleFonts.jetBrainsMono(fontSize: 13)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'Email: $email\nPassword: $password'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Credentials copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditPermissionsDialog(Map<String, dynamic> agent) async {
    final current = ((agent['permissions'] as List<dynamic>?) ?? const [])
        .map((e) => e.toString())
        .toSet();
    final selected = Set<String>.from(current);
    bool saving = false;

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(
              'Edit Permissions • ${agent['firstName']} ${agent['lastName']}'.trim(),
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: kAllSalesPermissions.map((perm) {
                    return CheckboxListTile(
                      dense: true,
                      value: selected.contains(perm.key),
                      activeColor: const Color(0xFF059669),
                      title: Text(perm.label, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      subtitle: Text('${perm.group} • ${perm.key}', style: GoogleFonts.jetBrainsMono(fontSize: 10)),
                      onChanged: (v) {
                        setDialogState(() {
                          if (v == true) {
                            selected.add(perm.key);
                          } else {
                            selected.remove(perm.key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        setDialogState(() => saving = true);
                        try {
                          final api = context.read<OrderBloc>().apiClient;
                          await api.patch(
                            ApiEndpoints.adminSalesAgentPermissions(agent['id'].toString()),
                            body: {'permissions': selected.toList()},
                            requiresAuth: true,
                          );
                          if (ctx.mounted) Navigator.of(ctx).pop(true);
                        } catch (e) {
                          setDialogState(() => saving = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to update permissions: $e')),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
                child: Text(saving ? 'Saving...' : 'Save & Sync Live'),
              ),
            ],
          );
        },
      ),
    );

    if (updated == true && mounted) {
      await _loadAgents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions updated & synced live via WebSocket.'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    }
  }

  Future<void> _toggleBlock(Map<String, dynamic> agent) async {
    final isBlocked = agent['isBlocked'] == true;
    try {
      final api = context.read<OrderBloc>().apiClient;
      await api.patch(
        ApiEndpoints.adminSalesAgentStatus(agent['id'].toString()),
        body: {'blocked': !isBlocked},
        requiresAuth: true,
      );
      await _loadAgents();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Future<void> _resetPassword(Map<String, dynamic> agent) async {
    try {
      final api = context.read<OrderBloc>().apiClient;
      final res = await api.patch(
        ApiEndpoints.adminSalesAgentStatus(agent['id'].toString()),
        body: {'resetPassword': true},
        requiresAuth: true,
      );
      final data = res['data'] is Map ? Map<String, dynamic>.from(res['data'] as Map) : const {};
      final pwd = data['generatedPassword']?.toString() ?? '';
      if (pwd.isNotEmpty && mounted) {
        await _showCredentialsDialog(agent['email']?.toString() ?? '', pwd);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reset password: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF161E2E) : Colors.white;
    final border = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final activeCount = _agents.where((a) => a['isBlocked'] != true).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sales Team Access Management',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create sales agent accounts and control tab & feature permissions in real time via WebSocket.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _openCreateAgentDialog,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
              label: Text('Create Sales Agent', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _kpiCard('Total Sales Agents', '${_agents.length}', const Color(0xFF059669), isDark, surface, border),
            const SizedBox(width: 12),
            _kpiCard('Active Access', '$activeCount', const Color(0xFF2563EB), isDark, surface, border),
            const SizedBox(width: 12),
            _kpiCard('Blocked / Suspended', '${_agents.length - activeCount}', const Color(0xFFDC2626), isDark, surface, border),
          ],
        ),
        const SizedBox(height: 18),
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFDC2626))),
          ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_agents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Center(
              child: Text(
                'No sales agents created yet. Click "Create Sales Agent" to generate credentials and assign tabs.',
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: const Color(0xFF64748B)),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _agents.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: border),
              itemBuilder: (context, index) {
                final agent = _agents[index];
                final name = '${agent['firstName'] ?? ''} ${agent['lastName'] ?? ''}'.trim();
                final email = agent['email']?.toString() ?? '';
                final isBlocked = agent['isBlocked'] == true;
                final perms = ((agent['permissions'] as List<dynamic>?) ?? const [])
                    .map((e) => e.toString())
                    .toList();

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF059669).withValues(alpha: 0.12),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'S',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  name.isNotEmpty ? name : email,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isBlocked ? const Color(0xFFDC2626) : const Color(0xFF059669))
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    isBlocked ? 'BLOCKED' : 'ACTIVE',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isBlocked ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: ((agent['role'] == 'ROLE_MARKETING')
                                            ? const Color(0xFF7C3AED)
                                            : const Color(0xFF2563EB))
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    agent['role'] == 'ROLE_MARKETING' ? 'MARKETING' : 'SALES AGENT',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: (agent['role'] == 'ROLE_MARKETING')
                                          ? const Color(0xFF7C3AED)
                                          : const Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              email,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: perms.isEmpty
                                  ? [
                                      Text(
                                        'No permissions assigned',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          color: const Color(0xFFD97706),
                                        ),
                                      ),
                                    ]
                                  : perms.map((p) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          p,
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF2563EB),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _openEditPermissionsDialog(agent),
                            icon: const Icon(Icons.tune_rounded, size: 15),
                            label: const Text('Permissions'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _resetPassword(agent),
                            icon: const Icon(Icons.key_rounded, size: 15),
                            label: const Text('Reset Pass'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _toggleBlock(agent),
                            icon: Icon(
                              isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                              size: 15,
                              color: isBlocked ? const Color(0xFF059669) : const Color(0xFFDC2626),
                            ),
                            label: Text(isBlocked ? 'Enable' : 'Block'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _kpiCard(String title, String value, Color color, bool isDark, Color surface, Color border) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

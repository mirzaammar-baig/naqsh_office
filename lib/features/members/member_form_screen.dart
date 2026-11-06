import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naqsh_office/core/theme/app_input_decoration.dart';
import 'package:naqsh_office/core/theme/app_theme.dart';
import 'package:naqsh_office/core/utils/input_validators.dart';
import 'package:naqsh_office/core/widgets/form_widgets.dart';
import 'package:naqsh_office/features/members/member.dart';
import 'package:naqsh_office/features/members/members_notifier.dart';

class MemberFormScreen extends ConsumerStatefulWidget {
  const MemberFormScreen({super.key, this.member});

  // null ho to Add, member mile to Edit.
  final Member? member;

  @override
  ConsumerState<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends ConsumerState<MemberFormScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController relationNameController;
  late final TextEditingController cnicController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;
  late final TextEditingController addressController;
  late final TextEditingController cityController;

  String relationType = 'S/O';
  bool isOverseas = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.member;

    nameController = TextEditingController(text: existing?.fullName ?? '');
    relationNameController = TextEditingController(
      text: existing?.relationName ?? '',
    );
    cnicController = TextEditingController();
    phoneController = TextEditingController(text: existing?.phone ?? '');
    emailController = TextEditingController(text: existing?.email ?? '');
    addressController = TextEditingController(text: existing?.address ?? '');
    cityController = TextEditingController(text: existing?.city ?? '');

    relationType = existing?.relationType ?? 'S/O';
    isOverseas = existing?.isOverseas ?? false;
  }

  @override
  void dispose() {
    nameController.dispose();
    relationNameController.dispose();
    cnicController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    cityController.dispose();
    super.dispose();
  }

  void save() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final notifier = ref.read(membersProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final existing = widget.member;
    String message;

    if (existing != null) {
      notifier.updateMember(
        existing.copyWith(
          fullName: nameController.text.trim(),
          relationType: relationType,
          relationName: relationNameController.text.trim(),
          phone: phoneController.text.trim(),
          email: emailController.text.trim(),
          address: addressController.text.trim(),
          city: cityController.text.trim(),
          isOverseas: isOverseas,
        ),
      );
      message = 'Member ${existing.memberNo} updated';
    } else {
      final memberNo = notifier.nextMemberNo();
      notifier.addMember(
        Member(
          id: 'member-${memberNo.substring(2)}',
          societyId: 'demo-city',
          memberNo: memberNo,
          fullName: nameController.text.trim(),
          relationType: relationType,
          relationName: relationNameController.text.trim(),
          cnic: cnicController.text.replaceAll(RegExp(r'\D'), ''),
          phone: phoneController.text.trim(),
          email: emailController.text.trim(),
          address: addressController.text.trim(),
          city: cityController.text.trim(),
          isOverseas: isOverseas,
          isActive: true,
          createdAt: DateTime.now(),
        ),
      );
      message = 'Member $memberNo added';
    }

    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.member;

    return Scaffold(
      appBar: AppBar(
        title: Text(existing != null ? 'Edit Member' : 'Add Member'),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // Member No: locked (khud banta hai)
            LockedField(
              label: 'Member No',
              value: existing != null
                  ? existing.memberNo
                  : '${ref.read(membersProvider.notifier).nextMemberNo()} (automatic)',
            ),
            const SizedBox(height: 16),

            // Full Name
            TextFormField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 16),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
                LengthLimitingTextInputFormatter(60),
              ],
              decoration: appInputDecoration(label: 'Full Name'),
              validator: (value) =>
                  InputValidators.personName(value, 'Full name'),
            ),
            const SizedBox(height: 16),

            // Relation
            SegmentField<String>(
              label: 'Relation',
              value: relationType,
              options: const {'S/O': 'S/O', 'D/O': 'D/O', 'W/O': 'W/O'},
              onChanged: (value) {
                setState(() {
                  relationType = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Father or Husband Name
            TextFormField(
              controller: relationNameController,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 16),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
                LengthLimitingTextInputFormatter(60),
              ],
              decoration: appInputDecoration(label: 'Father or Husband Name'),
              validator: (value) =>
                  InputValidators.personName(value, 'Father or husband name'),
            ),
            const SizedBox(height: 16),

            // CNIC: edit mein locked aur masked
            if (existing != null)
              LockedField(label: 'CNIC', value: existing.maskedCnic)
            else
              TextFormField(
                controller: cnicController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 16),
                inputFormatters: [CnicInputFormatter()],
                decoration: appInputDecoration(
                  label: 'CNIC',
                  hint: '00000-0000000-0',
                ),
                validator: (value) {
                  final error = InputValidators.cnic(value);
                  if (error != null) {
                    return error;
                  }
                  final digits = value!.replaceAll(RegExp(r'\D'), '');
                  if (ref.read(membersProvider.notifier).cnicExists(digits)) {
                    return 'A member with this CNIC already exists.';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 16),

            // Overseas
            SegmentField<bool>(
              label: 'Overseas member',
              value: isOverseas,
              options: const {true: 'Yes', false: 'No'},
              onChanged: (value) {
                setState(() {
                  isOverseas = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 16),
              inputFormatters: InputValidators.phoneFormatters(
                isOverseas: isOverseas,
              ),
              decoration: appInputDecoration(
                label: 'Phone',
                hint: isOverseas ? '+971501234567' : '03001234567',
                helper: isOverseas
                    ? '+ followed by 8 to 15 digits'
                    : '11 digits, starting with 03',
              ),
              validator: (value) =>
                  InputValidators.phone(value, isOverseas: isOverseas),
            ),
            const SizedBox(height: 16),

            // Email (optional)
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 16),
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
              decoration: appInputDecoration(
                label: 'Email (optional)',
                hint: 'name@example.com',
              ),
              validator: InputValidators.email,
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: addressController,
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 16),
              inputFormatters: [LengthLimitingTextInputFormatter(200)],
              decoration: appInputDecoration(label: 'Address'),
              validator: (value) =>
                  InputValidators.requiredWithMax(value, 'Address', 200),
            ),
            const SizedBox(height: 16),

            // City
            TextFormField(
              controller: cityController,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 16),
              inputFormatters: [LengthLimitingTextInputFormatter(40)],
              decoration: appInputDecoration(label: 'City'),
              validator: (value) =>
                  InputValidators.requiredWithMax(value, 'City', 40),
            ),
            const SizedBox(height: 28),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  existing != null ? 'Save Changes' : 'Save Member',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
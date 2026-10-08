import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_theme.dart';
import 'demo_supplier_repository.dart';
import 'supplier_home.dart';
import 'supplier_repository.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool obscure = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      _message('Geçerli e-posta ve en az 6 karakterli şifre girin.');
      return;
    }
    setState(() => loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email.text.trim(),
        password: password.text,
      );
    } on AuthException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('İşlem tamamlanamadı. İnternet bağlantınızı kontrol edin.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.navy,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'B',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Tedarikçi paneline giriş',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ürünlerinizi, stoklarınızı ve salon siparişlerini yönetin.',
                    style: TextStyle(color: Colors.black54, height: 1.45),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: password,
                    obscureText: obscure,
                    onSubmitted: (_) => submit(),
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: loading ? null : submit,
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Giriş yap'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const SupplierRegistrationScreen(),
                            ),
                          ),
                    child: const Text('Tedarikçi hesabınız yok mu? Başvurun'),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () {
                        final profile = SupplierProfile(
                          id: 'demo-supplier',
                          companyName: 'Atlas Berber Ekipmanları',
                          status: 'approved',
                          contactName: 'Demo Tedarikçi',
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SupplierHome(
                              repository: DemoSupplierRepository(
                                Supabase.instance.client,
                              ),
                              profile: profile,
                              onRefreshProfile: () {},
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Uygulamayı incele'),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Bu uygulama yalnızca tedarikçiler içindir. Salon ve müşteri hesapları BarBer uygulamasından giriş yapar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SupplierRegistrationScreen extends StatefulWidget {
  const SupplierRegistrationScreen({super.key});

  @override
  State<SupplierRegistrationScreen> createState() =>
      _SupplierRegistrationScreenState();
}

class _SupplierRegistrationScreenState
    extends State<SupplierRegistrationScreen> {
  final company = TextEditingController();
  final contact = TextEditingController();
  final phone = TextEditingController();
  final taxOffice = TextEditingController();
  final taxNumber = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final passwordAgain = TextEditingController();
  bool accepted = false;
  bool loading = false;
  bool obscure = true;

  @override
  void dispose() {
    for (final controller in [
      company,
      contact,
      phone,
      taxOffice,
      taxNumber,
      email,
      password,
      passwordAgain,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if ([
      company,
      contact,
      phone,
      taxOffice,
      taxNumber,
      email,
      password,
      passwordAgain,
    ].any((controller) => controller.text.trim().isEmpty)) {
      _message('Lütfen tüm alanları doldurun.');
      return;
    }
    if (!email.text.contains('@')) {
      _message('Geçerli bir e-posta adresi girin.');
      return;
    }
    if (password.text.length < 8) {
      _message('Şifreniz en az 8 karakter olmalıdır.');
      return;
    }
    if (password.text != passwordAgain.text) {
      _message('Şifreler birbiriyle eşleşmiyor.');
      return;
    }
    if (!accepted) {
      _message('Devam etmek için sözleşmeleri onaylayın.');
      return;
    }

    setState(() => loading = true);
    try {
      final result = await Supabase.instance.client.auth.signUp(
        email: email.text.trim(),
        password: password.text,
        data: {
          'app_role': 'supplier',
          'company_name': company.text.trim(),
          'contact_name': contact.text.trim(),
          'phone': phone.text.trim(),
          'tax_office': taxOffice.text.trim(),
          'tax_number': taxNumber.text.trim(),
        },
      );
      if (!mounted) return;
      if (result.session == null) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.mark_email_read_outlined,
              color: AppTheme.orange,
              size: 42,
            ),
            title: const Text('E-postanızı doğrulayın'),
            content: Text(
              '${email.text.trim()} adresine doğrulama bağlantısı gönderdik. Doğruladıktan sonra giriş yapabilirsiniz.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('Kayıt tamamlanamadı. İnternet bağlantınızı kontrol edin.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tedarikçi başvurusu',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'BarBer salonlarına satış yapın',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Firma hesabınızı oluşturun. Bilgileriniz kontrol edildikten sonra mağazanız satışa açılır.',
                    style: TextStyle(color: Colors.black54, height: 1.45),
                  ),
                  const SizedBox(height: 24),
                  const _FormSectionTitle('Firma bilgileri'),
                  const SizedBox(height: 12),
                  _field(company, 'Firma unvanı', Icons.business_outlined),
                  _field(contact, 'Yetkili kişi', Icons.person_outline),
                  _field(
                    phone,
                    'Telefon',
                    Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          taxOffice,
                          'Vergi dairesi',
                          Icons.account_balance_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _field(
                          taxNumber,
                          'Vergi numarası',
                          Icons.numbers_outlined,
                          keyboard: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const _FormSectionTitle('Giriş bilgileri'),
                  const SizedBox(height: 12),
                  _field(
                    email,
                    'E-posta',
                    Icons.mail_outline,
                    keyboard: TextInputType.emailAddress,
                  ),
                  _field(
                    password,
                    'Şifre',
                    Icons.lock_outline,
                    isPassword: true,
                  ),
                  _field(
                    passwordAgain,
                    'Şifre tekrar',
                    Icons.lock_reset_outlined,
                    isPassword: true,
                  ),
                  CheckboxListTile(
                    value: accepted,
                    onChanged: (value) =>
                        setState(() => accepted = value ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'Kullanım koşullarını ve tedarikçi sözleşmesini okudum, kabul ediyorum.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: loading ? null : submit,
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Hesabı oluştur ve başvur'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tedarikçi hesabı, BarBer müşteri veya salon hesabı olarak kullanılamaz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        obscureText: isPassword && obscure,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: () => setState(() => obscure = !obscure),
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _FormSectionTitle extends StatelessWidget {
  const _FormSectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: AppTheme.navy,
    ),
  );
}

class SupplierApplicationScreen extends StatefulWidget {
  const SupplierApplicationScreen({
    super.key,
    required this.repository,
    required this.onSaved,
  });

  final SupplierRepository repository;
  final VoidCallback onSaved;

  @override
  State<SupplierApplicationScreen> createState() =>
      _SupplierApplicationScreenState();
}

class _SupplierApplicationScreenState extends State<SupplierApplicationScreen> {
  final company = TextEditingController();
  final contact = TextEditingController();
  final phone = TextEditingController();
  final taxNumber = TextEditingController();
  final taxOffice = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    for (final controller in [company, contact, phone, taxNumber, taxOffice]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if ([
      company,
      contact,
      phone,
      taxNumber,
      taxOffice,
    ].any((e) => e.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
      );
      return;
    }
    setState(() => loading = true);
    try {
      await widget.repository.submitApplication(
        companyName: company.text,
        contactName: contact.text,
        phone: phone.text,
        taxNumber: taxNumber.text,
        taxOffice: taxOffice.text,
      );
      widget.onSaved();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Başvuru kaydedilemedi: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tedarikçi başvurusu'),
        actions: [
          IconButton(
            onPressed: () => Supabase.instance.client.auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: AppTheme.orange,
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Firma bilgilerinizi kontrol ettikten sonra ürün ekleme yetkiniz açılacaktır.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                for (final field in [
                  (company, 'Firma unvanı', Icons.business_outlined),
                  (contact, 'Yetkili kişi', Icons.person_outline),
                  (phone, 'Telefon', Icons.phone_outlined),
                  (taxOffice, 'Vergi dairesi', Icons.account_balance_outlined),
                  (taxNumber, 'Vergi numarası', Icons.numbers_outlined),
                ]) ...[
                  TextField(
                    controller: field.$1,
                    decoration: InputDecoration(
                      labelText: field.$2,
                      prefixIcon: Icon(field.$3),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                FilledButton(
                  onPressed: loading ? null : save,
                  child: Text(loading ? 'Kaydediliyor…' : 'Başvuruyu gönder'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

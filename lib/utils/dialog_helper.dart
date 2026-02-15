import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';
import 'package:google_fonts/google_fonts.dart';

class DialogHelper {
  static void showError(BuildContext context, String title, String desc) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.bottomSlide,
      title: title,
      desc: desc,
      titleTextStyle:
          GoogleFonts.kanit(fontSize: 18, fontWeight: FontWeight.bold),
      descTextStyle: GoogleFonts.kanit(fontSize: 14),
      btnOkOnPress: () {},
      btnOkText: 'ตกลง',
    ).show();
  }

  static void showSuccess(BuildContext context, String title, [String? desc]) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.bottomSlide,
      title: title,
      desc: desc,
      titleTextStyle:
          GoogleFonts.kanit(fontSize: 18, fontWeight: FontWeight.bold),
      descTextStyle: GoogleFonts.kanit(fontSize: 14),
      btnOkOnPress: () {},
      btnOkText: 'ตกลง',
    ).show();
  }

  static void showWarning(BuildContext context, String title, String desc) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.bottomSlide,
      title: title,
      desc: desc,
      titleTextStyle:
          GoogleFonts.kanit(fontSize: 18, fontWeight: FontWeight.bold),
      descTextStyle: GoogleFonts.kanit(fontSize: 14),
      btnOkOnPress: () {},
      btnOkText: 'ตกลง',
      btnOkColor: Colors.orange,
    ).show();
  }

  static AwesomeDialog showLoading(BuildContext context, String title) {
    AwesomeDialog dialog = AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(title, style: GoogleFonts.kanit(fontSize: 16)),
          ],
        ),
      ),
      dismissOnTouchOutside: false,
      dismissOnBackKeyPress: false,
    );
    dialog.show();
    return dialog;
  }
}

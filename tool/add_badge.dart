import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  // Use the original backup if available, otherwise the current one
  String path = 'assets/launcher/launcher_original.png';
  if (!File(path).existsSync()) {
    path = 'assets/launcher/launcher.png';
    // Back it up first if we haven't yet (though we should have)
    if (!File('assets/launcher/launcher_original.png').existsSync()) {
      await File(path).copy('assets/launcher/launcher_original.png');
    }
  }

  final file = File(path);
  final bytes = await file.readAsBytes();
  final image = img.decodeImage(bytes);

  if (image == null) {
    print('Failed to decode image');
    return;
  }

  final width = image.width;
  final height = image.height;

  // Make a very large red banner at the bottom (approx 25% of height)
  final bannerHeight = (height * 0.25).toInt();
  final bannerY = height - bannerHeight;

  img.fillRect(image,
      x1: 0,
      y1: bannerY,
      x2: width,
      y2: height,
      color: img.ColorRgb8(255, 0, 0));

  // Create a separate image for text to scale it up
  // arial48 is ~48px high. We want it to fill the banner (e.g. ~200px for 1024px icon)
  // So we need to scale up by ~4x-5x

  final text = ' DEMO ';
  final font = img.arial48;

  // Estimate text size
  // There isn't a direct measureText, but chars are roughly fixed width in basics or we can guess.
  // 48px font, let's assume ~30px width per char? 6 chars = 180px.
  // We'll create a canvas enough for it.
  final textCanvas = img.Image(width: 400, height: 80);
  // Fill transparent? Image starts transparent black usually (0,0,0,0)

  img.drawString(textCanvas, text,
      font: font, x: 10, y: 10, color: img.ColorRgb8(255, 255, 255));

  // Trim the text image to content if possible or just scale the whole thing.
  // Let's just scale the textCanvas up.
  // We want the text to be centered in the banner.

  // Scale factor based on image width.
  // If image is 1024, we want text to be maybe 80% width?
  // Current text width ~ 400 (canvas).
  // Target width ~ 800. Scale ~ 2-3x.

  // Better approach: Resize "textCanvas" using nearest neighbor or linear to be BIG.
  final scale = (width / 400.0) * 0.8; // Scale to 80% of width roughly
  final targetW = (textCanvas.width * scale).toInt();
  final targetH = (textCanvas.height * scale).toInt();

  final scaledText = img.copyResize(textCanvas,
      width: targetW, height: targetH, interpolation: img.Interpolation.cubic);

  // Composite it centered in the banner
  final textX = (width - targetW) ~/ 2;
  final textY = bannerY + (bannerHeight - targetH) ~/ 2;

  // Alpha blend? copyInto handles it
  img.compositeImage(image, scaledText, dstX: textX, dstY: textY);

  final outPath = 'assets/launcher/launcher.png';
  await File(outPath).writeAsBytes(img.encodePng(image));
  print('Created $outPath with BIG badge');
}

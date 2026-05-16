import javax.imageio.ImageIO;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;

public class GenerateLauncherIcons {
    private static final String SOURCE = "assets/images/ambedkar.jpg";

    public static void main(String[] args) throws IOException {
        BufferedImage source = ImageIO.read(new File(SOURCE));
        if (source == null) {
            throw new IOException("Unable to read " + SOURCE);
        }

        write(source, "android/app/src/main/res/mipmap-mdpi/ic_launcher.png", 48);
        write(source, "android/app/src/main/res/mipmap-hdpi/ic_launcher.png", 72);
        write(source, "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png", 96);
        write(source, "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png", 144);
        write(source, "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png", 192);

        write(source, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png", 20);
        write(source, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png", 40);
        write(source, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png", 60);
        write(source, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png", 29);
        write(source, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png", 58);
        write(source, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png", 87);
        write(source, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png", 40);
        write(source, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png", 80);
        write(source, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png", 120);
        write(source, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png", 120);
        write(source, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png", 180);
        write(source, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png", 76);
        write(source, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png", 152);
        write(source, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png", 167);
        write(source, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png", 1024);
    }

    private static void write(BufferedImage source, String path, int size) throws IOException {
        File output = new File(path);
        output.getParentFile().mkdirs();
        ImageIO.write(resizeSquare(source, size), "png", output);
    }

    private static BufferedImage resizeSquare(BufferedImage source, int size) {
        int crop = Math.min(source.getWidth(), source.getHeight());
        int x = (source.getWidth() - crop) / 2;
        int y = (source.getHeight() - crop) / 2;
        BufferedImage target = new BufferedImage(size, size, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = target.createGraphics();
        g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
        g.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
        g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g.drawImage(source, 0, 0, size, size, x, y, x + crop, y + crop, null);
        g.dispose();
        return target;
    }
}

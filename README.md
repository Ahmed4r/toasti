# Toasti 🍞

A beautiful, highly customizable, premium iOS-style glassmorphism toast overlay for Flutter.

## Features ✨

* **Glassmorphism Design:** High-quality frosted glass blur effect natively built for a premium look.
* **Animated Icons:** Built-in, meticulously crafted animations for "success", "warning", and "error" states.
* **Global Overlay:** Use the "showToasti()" function globally from anywhere in your app to show the toast on top of everything.
* **Interactive:** Built-in swipe-up-to-dismiss gesture support.
* **Highly Customizable:** Easily override backgrounds, text styles, constraints, and animations.
* **Responsive:** Automatically scales constraints down beautifully for smaller screens.

## Installation 💻

Add the package to your "pubspec.yaml":

`yaml
dependencies:
  toast: ^1.0.0
``n
Run "flutter pub get" to install.

## Usage 🚀

Import the package where you want to trigger the toast:

`dart
import 'package:toast/toasti.dart';
``n
Call the globally available "showToasti" function from any action!

### Basic Example

`dart
ElevatedButton(
  onPressed: () {
    showToasti(
      context,
      title: 'Charger reserved',
      description: 'Opera Passage station reserved successfully.',
      type: ToastType.success,
      duration: const Duration(seconds: 4),
    );
  },
  child: const Text('Show Success Toast'),
)
``n
### Toast Types

"Toasti" comes with three predefined beautifully animated states:
* "ToastType.success" - Checkmark draws itself incrementally.
* "ToastType.warning" - Exclamation drops down with a fading/pulsing dot.
* "ToastType.error" - Continuously scaling/pulsing red 'X' mark.

### Customization Example

You can heavily customize the look, feel, and typography of the toast. You can even disable the animations if you prefer a static UI.

`dart
showToasti(
  context,
  title: 'Custom Warning',
  description: 'This is a custom warning with a custom styled background.',
  type: ToastType.warning,
  duration: const Duration(seconds: 5),
  backgroundColor: Colors.blue.withOpacity(0.5), // Override background glass color
  titleStyle: const TextStyle(
    fontSize: 20,
    color: Colors.yellowAccent,
  ),
  descriptionStyle: const TextStyle(
    fontStyle: FontStyle.italic,
  ),
  enableAnimation: false, // Turn off active animations
  width: 400, // Custom width constraint
);
``n
## Contributing 🤝

Contributions are welcome! Feel free to open an issue or submit a pull request if you have ideas on how to improve this package.

## License 📜

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

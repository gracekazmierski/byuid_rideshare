// lib/screens/welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:byui_rideshare/theme/app_colors.dart';
// Note: Ensure your navigation routes '/login' and '/create_account' are correctly set up.
// import 'package:byui_rideshare/screens/auth/login_page.dart';
// import 'package:byui_rideshare/screens/auth/create_account_page.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // SVG icon data from your TypeScript file
    const String rideshareIconSvg = '''
      <svg
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
        xmlns="http://www.w3.org/2000/svg">
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"
        />
      </svg>
    ''';

    return Scaffold(
      // Set the background color to a light gray, similar to 'bg-gray-100'
      backgroundColor: const Color(0xFFF3F4F6),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              16.0,
              60.0,
              16.0,
              24.0,
            ), // Adjusted padding for status bar
            color: AppColors.byuiBlue, // 'bg-byui-blue'
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to RexRide',
                  style: TextStyle(
                    color: Colors.white, // 'text-white'
                    fontSize: 24.0, // 'text-2xl'
                    fontWeight: FontWeight.w600, // 'font-semibold'
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  'Student Run. Student Focused.',
                  style: TextStyle(
                    color: Color(0xFFC7D2FE), // Approximates 'text-blue-100'
                    fontSize: 14.0, // 'text-sm'
                  ),
                ),
              ],
            ),
          ),

          // Main Content Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ), // 'px-6 py-8'
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 448,
                  ), // 'max-w-md'
                  child: Container(
                    padding: const EdgeInsets.all(32.0), // 'p-8'
                    decoration: BoxDecoration(
                      color: Colors.white, // 'bg-white'
                      borderRadius: BorderRadius.circular(8.0), // 'rounded-lg'
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ), // 'border'
                      boxShadow: [
                        // 'shadow-sm'
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10.0,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        Container(
                          width: 64.0, // 'w-16'
                          height: 64.0, // 'h-16'
                          decoration: const BoxDecoration(
                            color: AppColors.byuiBlue, // 'bg-byui-blue'
                            shape: BoxShape.circle, // 'rounded-full'
                          ),
                          child: Center(
                            child: SvgPicture.string(
                              rideshareIconSvg,
                              width: 32.0, // 'w-8'
                              height: 32.0, // 'h-8'
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ), // 'text-white'
                            ),
                          ),
                        ),
                        const SizedBox(height: 24.0), // 'space-y-6'
                        // Description
                        const Text(
                          'Connect with students for safe and convenient rides.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF4B5563), // 'text-gray-600'
                            fontSize: 14.0, // 'text-sm'
                          ),
                        ),
                        const SizedBox(height: 24.0), // 'space-y-6'
                        // Buttons
                        SizedBox(
                          width: double.infinity, // 'w-full'
                          height: 48.0, // 'h-12'
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppColors.byuiBlue, // 'bg-byui-blue'
                              foregroundColor: Colors.white, // 'text-white'
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  8.0,
                                ), // 'rounded-lg'
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w500, // 'font-medium'
                              ),
                            ),
                            child: const Text('Log In'),
                          ),
                        ),
                        const SizedBox(height: 16.0), // 'space-y-4'
                        SizedBox(
                          width: double.infinity, // 'w-full'
                          height: 48.0, // 'h-12'
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/create_account');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  AppColors.byuiBlue, // 'text-byui-blue'
                              side: const BorderSide(
                                color: AppColors.byuiBlue,
                              ), // 'border-byui-blue'
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  8.0,
                                ), // 'rounded-lg'
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w500, // 'font-medium'
                              ),
                            ).copyWith(
                              // Replicates 'hover:bg-byui-blue hover:text-white'
                              overlayColor: MaterialStateProperty.resolveWith<
                                Color?
                              >((Set<MaterialState> states) {
                                if (states.contains(MaterialState.hovered) ||
                                    states.contains(MaterialState.pressed)) {
                                  return AppColors.byuiBlue;
                                }
                                return null; // Defer to the widget's default.
                              }),
                              foregroundColor:
                                  MaterialStateProperty.resolveWith<Color?>((
                                    Set<MaterialState> states,
                                  ) {
                                    if (states.contains(
                                          MaterialState.hovered,
                                        ) ||
                                        states.contains(
                                          MaterialState.pressed,
                                        )) {
                                      return Colors.white;
                                    }
                                    return AppColors
                                        .byuiBlue; // Default text color
                                  }),
                            ),
                            child: const Text('Create an account'),
                          ),
                        ),
                      ],
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

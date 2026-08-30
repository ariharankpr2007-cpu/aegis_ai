import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../citizen/bottom_navigation.dart';
import '../rescue/rescue_dashboard.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
 
final ImagePicker picker = ImagePicker();

File? aadharImage;

final TextEditingController aadharController =
    TextEditingController();

bool uploading = false;
  bool hidePassword = true;
  bool aadhaarConfirmed = false;

final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController =
    TextEditingController();
final TextEditingController lastNameController =
    TextEditingController();
final TextEditingController emailController =
    TextEditingController();
final TextEditingController phoneController =
    TextEditingController();
final TextEditingController passwordController =
    TextEditingController();
final TextEditingController confirmPasswordController =
    TextEditingController();

DateTime? dateOfBirth;
  Future<String?> uploadToCloudinary(File imageFile) async {
  const cloudName = "xxsz8t3v";
  const uploadPreset = "aegis_rescue_proof";

  final url = Uri.parse(
    "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
  );

  final request = http.MultipartRequest("POST", url);

  request.fields["upload_preset"] = uploadPreset;

  request.files.add(
    await http.MultipartFile.fromPath(
      "file",
      imageFile.path,
    ),
  );

  final response = await request.send();

  final responseBody = await response.stream.bytesToString();

  if (response.statusCode == 200) {
    final data = jsonDecode(responseBody);
    return data["secure_url"];
  }

  print("Cloudinary upload failed: $responseBody");
  return null;
}
@override
void dispose() {
  firstNameController.dispose();
  lastNameController.dispose();
  emailController.dispose();
  phoneController.dispose();
  passwordController.dispose();
  confirmPasswordController.dispose();
  aadharController.dispose();
  super.dispose();
}
Future registerUser() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }
  if (!aadhaarConfirmed) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Please confirm that the Aadhaar belongs to you.",
        ),
      ),
    );
    return;
  }

  try {
    UserCredential userCredential =
        await auth.createUserWithEmailAndPassword(
          
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );
    print("REGISTER UID: ${userCredential.user?.uid}");
print("REGISTER EMAIL: ${userCredential.user?.email}");
print("CURRENT USER: ${FirebaseAuth.instance.currentUser?.email}");
    String? aadharUrl;
    await firestore
    .collection("users")
    .doc(userCredential.user!.uid)
    .set({
  "name":
    "${firstNameController.text.trim()} ${lastNameController.text.trim()}",
  "email": emailController.text.trim(),
  "phone": phoneController.text.trim(),
  "dateOfBirth": Timestamp.fromDate(dateOfBirth!),
  "role": "Citizen",

"isApproved": true,
"verificationStatus": "Approved",
  "aadharUrl": aadharUrl,
  "createdAt": Timestamp.now(),
});
  
    if (!mounted) return;

Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(
    builder: (_) => const BottomNavigation(),
  ),
  (route) => false,
);
  } on FirebaseAuthException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.message ?? "Registration Failed"),
      ),
    );
  }
}
Future<void> pickAadharImage() async {
  final XFile? image =
      await picker.pickImage(source: ImageSource.gallery);

  if (image != null) {
    setState(() {
      aadharImage = File(image.path);
    });
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0B3D91),

      appBar: AppBar(
  backgroundColor: const Color(0xff0B3D91),
  foregroundColor: Colors.white,
  elevation: 0,

  leading: IconButton(
    icon: const Icon(
      Icons.arrow_back_rounded,
      color: Colors.white,
    ),
    onPressed: () {
      Navigator.pop(context);
    },
  ),

  title: const Text("Create Account"),
),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Form(
  key: _formKey,
  child: Column(
    children: [

  TextFormField(
    controller: firstNameController,
    textCapitalization: TextCapitalization.words,
    decoration: const InputDecoration(
      labelText: "First Name",
      prefixIcon: Icon(Icons.person),
      border: OutlineInputBorder(),
    ),
    validator: (value) {
      final firstName = value?.trim() ?? "";

      if (firstName.isEmpty) {
        return "Please enter your first name";
      }

      return null;
    },
  ),

  const SizedBox(height: 15),

  TextFormField(
    controller: lastNameController,
    textCapitalization: TextCapitalization.words,
    decoration: const InputDecoration(
      labelText: "Last Name",
      prefixIcon: Icon(Icons.person_outline),
      border: OutlineInputBorder(),
    ),
    validator: (value) {
      final lastName = value?.trim() ?? "";

      if (lastName.isEmpty) {
        return "Please enter your last name";
      }

      return null;
    },
  ),

  const SizedBox(height: 15),

  TextFormField(
    controller: phoneController,
    keyboardType: TextInputType.phone,
    maxLength: 10,
  decoration: const InputDecoration(
    labelText: "Phone Number",
    prefixText: "+91 ",
    prefixIcon: Icon(Icons.phone),
    counterText: "",
    border: OutlineInputBorder(),
  ),
  validator: (value) {
    final phone = value?.trim() ?? "";

    if (phone.isEmpty) {
      return "Please enter your phone number";
    }

    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
      return "Enter a valid 10-digit Indian mobile number";
    }

    return null;
  },
),

              const SizedBox(height: 15),

              TextFormField(
  controller: emailController,
  keyboardType: TextInputType.emailAddress,
  decoration: const InputDecoration(
    labelText: "Email",
    prefixIcon: Icon(Icons.email),
  ),
  validator: (value) {
    final email = value?.trim() ?? "";

    if (email.isEmpty) {
      return "Please enter your email";
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      return "Please enter a valid email address";
    }

    return null;
  },
),        
const SizedBox(height: 15),

FormField<DateTime>(
  validator: (_) {
    if (dateOfBirth == null) {
      return "Please select your date of birth";
    }
    return null;
  },
  builder: (field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime(
                DateTime.now().year - 18,
              ),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );

            if (pickedDate != null) {
              setState(() {
                dateOfBirth = pickedDate;
              });

              field.didChange(pickedDate);
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: "Date of Birth",
              prefixIcon: Icon(Icons.calendar_today),
              border: OutlineInputBorder(),
            ),
            child: Text(
              dateOfBirth == null
                  ? "Select your date of birth"
                  : "${dateOfBirth!.day.toString().padLeft(2, '0')}/"
                    "${dateOfBirth!.month.toString().padLeft(2, '0')}/"
                    "${dateOfBirth!.year}",
              style: TextStyle(
                color: dateOfBirth == null
                    ? Colors.grey
                    : Colors.black,
              ),
            ),
          ),
        ),
        if (field.hasError)
          Padding(
            padding: const EdgeInsets.only(
              left: 12,
              top: 6,
            ),
            child: Text(
              field.errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  },
),
              const SizedBox(height: 15),

              TextFormField(
  controller: passwordController,
  obscureText: hidePassword,
  decoration: InputDecoration(
    labelText: "Password",
    prefixIcon: const Icon(Icons.lock),
    suffixIcon: IconButton(
      icon: Icon(
        hidePassword
            ? Icons.visibility
            : Icons.visibility_off,
      ),
      onPressed: () {
        setState(() {
          hidePassword = !hidePassword;
        });
      },
    ),
  ),
  validator: (value) {
    final password = value ?? "";

    if (password.isEmpty) {
      return "Please enter a password";
    }

    if (password.length < 6) {
      return "Password must be at least 6 characters";
    }

    return null;
  },
),
const SizedBox(height: 15),

TextFormField(
  controller: confirmPasswordController,
  obscureText: hidePassword,
  decoration: const InputDecoration(
    labelText: "Confirm Password",
    prefixIcon: Icon(Icons.lock_outline),
    border: OutlineInputBorder(),
  ),
  validator: (value) {
    final confirmPassword = value ?? "";

    if (confirmPassword.isEmpty) {
      return "Please confirm your password";
    }

    if (confirmPassword != passwordController.text) {
      return "Passwords do not match";
    }

    return null;
  },
),
                
const SizedBox(height: 15),

TextFormField(
  controller: aadharController,
  keyboardType: TextInputType.number,
  maxLength: 12,
  decoration: const InputDecoration(
    labelText: "Aadhaar Number",
    prefixIcon: Icon(Icons.credit_card),
    counterText: "",
  ),
  validator: (value) {
    final aadhaar = value?.trim() ?? "";

    if (aadhaar.isEmpty) {
      return "Please enter your Aadhaar number";
    }

    if (!RegExp(r'^[0-9]{12}$').hasMatch(aadhaar)) {
      return "Aadhaar number must contain 12 digits";
    }

    return null;
  },
),

const SizedBox(height: 15),

SizedBox(
  width: double.infinity,
  height: 55,
  child: OutlinedButton.icon(
    onPressed: pickAadharImage,
    icon: const Icon(Icons.upload_file),
    label: const Text("Upload Aadhaar Front"),
  ),
),

const SizedBox(height: 15),

if (aadharImage != null)
  ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.file(
      aadharImage!,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
    ),
  ),

const SizedBox(height: 15),

CheckboxListTile(
  value: aadhaarConfirmed,
  onChanged: (value) {
    setState(() {
      aadhaarConfirmed = value ?? false;
    });
  },
  title: const Text(
    "I confirm this Aadhaar belongs to me.",
  ),
  controlAffinity: ListTileControlAffinity.leading,
),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0B3D91),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: registerUser,
                  child: const Text(
                    "REGISTER",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

                       ],
          ),
        ),
      ),
    ),
  );
}
}
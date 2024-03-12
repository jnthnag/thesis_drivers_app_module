import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thesis_drivers_app_module/pages/dashboard.dart';
import '../methods/common_methods.dart';
import '../widgets/loading_dialog.dart';
import 'login_screen.dart';
import 'dart:io';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // initialize objects for Name, Phone, Email, Password
  //TextEditingController userNameTextEditingController = TextEditingController();
  // TextEditingController userPhoneTextEditingController = TextEditingController();
  // TextEditingController emailTextEditingController = TextEditingController();
  // TextEditingController passwordTextEditingController = TextEditingController();
  CommonMethods common = CommonMethods();
  XFile? imageFile;
  String urlOfUploadedImage = "";

  checkIfNetworkIsAvailable() {
    common.checkConnectivity(context);

    if(imageFile != null)
      {
        signUpFormValidation();
      }
    else
      {
        common.displaySnackbar("Please choose image first.", context);
      }
  }

  uploadImageToStorage() async
  {
    // use Date and Time to generate a unique ID for the image
    String imageIDName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference referenceImage = FirebaseStorage.instance.ref().child("Images").child(imageIDName);

    UploadTask uploadTask = referenceImage.putFile(File(imageFile!.path));
    TaskSnapshot snapshot = await uploadTask;
    urlOfUploadedImage = await snapshot.ref.getDownloadURL();

    setState(() {
      urlOfUploadedImage;
    });

    registerNewDriver();

  }

  signUpFormValidation() {
    if (common.userNameTextEditingController.text.trim().length < 3)
    {
      common.displaySnackbar("Your username must be at least 4 or more characters", context);
    }
    else if (common.userPhoneTextEditingController.text.trim().length != 11)
    {
      common.displaySnackbar("Your phone number length must be 11 ", context);
    }
    else if (!common.emailTextEditingController.text.contains("@"))
    {
      common.displaySnackbar("Please write a valid email", context);
    }
    else if (common.passwordTextEditingController.text.length < 5)
    {
      common.displaySnackbar("Your password must be at least 6 or more characters", context);
    }
    else if (common.vehicleModelTextEditingController.text.isEmpty)
    {
      common.displaySnackbar("Vehicle model is a required field", context);
    }
    else if (common.vehicleColorTextEditingController.text.isEmpty)
    {
      common.displaySnackbar("Vehicle Color is a required field", context);
    }
    else if (common.vehiclePlateNumberTextEditingController.text.isEmpty)
    {
      common.displaySnackbar("Vehicle plate number is a required field", context);
    }
    else
    {
      uploadImageToStorage();
    }
  }

  registerNewDriver() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            const LoadingDialog(messageText: "Registering your account"));
    final User? userFirebase = (await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email: common.emailTextEditingController.text.trim(),
      password: common.passwordTextEditingController.text.trim(),
    )
        .catchError((errorMessage) => common.displaySnackbar(errorMessage.toString(), context)))
        .user;
    if (!context.mounted) return;
    Navigator.pop(context);

    DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("drivers").child(userFirebase!.uid);
    // Driver Car information Data Map
    Map driverCarInfo =
    {
      "carColor" : common.vehicleColorTextEditingController.text.trim(),
      "carModel" : common.vehicleModelTextEditingController.text.trim(),
      "carPlateNumber" : common.vehiclePlateNumberTextEditingController.text.trim(),
    };

    // Driver personal information Data Map
    Map driverDataMap = {
      "photo" : urlOfUploadedImage,
      "car_details" : driverCarInfo,
      "name" : common.userNameTextEditingController.text.trim(),
      "email" : common.emailTextEditingController.text.trim(),
      "phone" : common.userPhoneTextEditingController.text.trim(),
      "id" : userFirebase.uid,
      "blockStatus" : "no",
    };

    usersRef.set(driverDataMap);
    Navigator.push(context, MaterialPageRoute(builder: (c) => const Dashboard()));
  }

  chooseImageFromGallery() async
  {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if(pickedFile != null)
      {
        setState(() {
          imageFile = pickedFile;
        });
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [

              const SizedBox(
                height: 70,
              ),
              imageFile == null ?
              const CircleAvatar(
                radius: 70,
                backgroundImage: AssetImage("assets/images/avatarman.png"),
              ) : Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                  image: DecorationImage(
                    fit: BoxFit.fitHeight,
                    image: FileImage(
                      File(
                        imageFile!.path,
                      ),
                     ),
                    )
                  )
                ),


              const SizedBox(
                height: 20,
              ),

              GestureDetector(
                onTap: ()
                {
                  chooseImageFromGallery();
                },

                child: const Text(
                  "Choose Image",
                  style: TextStyle(
                    fontFamily: null,
                    fontSize: 10,
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              const Text(
                "Create Driver Account",
                style: TextStyle(
                  fontFamily: null,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // TEXT FIELDS and ACTION BUTTON
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    TextField(
                      controller: common.userNameTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: "Driver Name",
                        labelStyle: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    TextField(
                      controller: common.userPhoneTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: "Driver Phone",
                        labelStyle: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    TextField(
                      controller: common.emailTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: "Driver Email",
                        labelStyle: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    TextField(
                      controller: common.passwordTextEditingController,
                      keyboardType: TextInputType.text,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Driver Password",
                        labelStyle: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    TextField(
                      controller: common.vehicleModelTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: "Vehicle Model",
                        labelStyle: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    TextField(
                      controller: common.vehicleColorTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: "Vehicle Color",
                        labelStyle: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    TextField(
                      controller: common.vehiclePlateNumberTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: "Vehicle Plate Number",
                        labelStyle: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        checkIfNetworkIsAvailable();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 80, vertical: 10)),
                      child: const Text("Sign Up"),
                    ),
                  ],
                ),
              ),

              // Sub text button for existing users
              TextButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (c) => const LoginScreen()));
                },
                child: const Text(
                  "Already Have an Account? Login Here",
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

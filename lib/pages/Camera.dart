import 'dart:developer';
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../methods/common_methods.dart';
import '../widgets/loading_dialog.dart';

class CameraPage extends StatefulWidget {
  
  final String? tripID;
  
  const CameraPage({super.key, required this.tripID});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {

  CommonMethods common = CommonMethods();
  XFile? pickupFile, destinationFile;
  String urlOfUploadedImage = "";

  uploadImageToPickUp() async
  {
    // use Date and Time to generate a unique ID for the image
    String imageIDName = DateTime.now().millisecondsSinceEpoch.toString();
    String jpg = ".jpg";
    String finalImageIDName = imageIDName + jpg;
    log("image name : $finalImageIDName");
    Reference referenceImage = FirebaseStorage.instance.ref().child("Images").child(finalImageIDName);
    UploadTask uploadTask = referenceImage.putFile(File(pickupFile!.path), SettableMetadata(contentType: "image/jpeg"));
    TaskSnapshot snapshot = await uploadTask;
    urlOfUploadedImage = await snapshot.ref.getDownloadURL();

    setState(() {
      urlOfUploadedImage;
    });
    return "done";
  }

  uploadImageToDropOff() async
  {
    // use Date and Time to generate a unique ID for the image
    String imageIDName = DateTime.now().millisecondsSinceEpoch.toString();
    String jpg = ".jpg";
    String finalImageIDName = imageIDName + jpg;
    log("image name : $finalImageIDName");
    Reference referenceImage = FirebaseStorage.instance.ref().child("Images").child(widget.tripID!).child(finalImageIDName);
    UploadTask uploadTask = referenceImage.putFile(File(destinationFile!.path));
    TaskSnapshot snapshot = await uploadTask;
    urlOfUploadedImage = await snapshot.ref.getDownloadURL();

    setState(() {
      urlOfUploadedImage;
    });

  }

  setImageToDatabase() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            const LoadingDialog(messageText: "Uploading Image"));
    DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("tripRequests").child(widget.tripID!).child("pickUpPhoto");
    Map imageMap = {
      "pickUpPhoto" : urlOfUploadedImage,
    };
    usersRef.set(imageMap);
    Navigator.pop(context);
    return "done";
  }

  chooseImageFromGalleryPickup() async
  {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if(pickedFile != null)
    {
      setState(() {
        pickupFile = pickedFile;
      });
    }

    return "done";
  }

  chooseImageFromGalleryDestination() async
  {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);

    if(pickedFile != null)
    {
      setState(() {
        destinationFile = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Images proof"),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black87,
        ),
        height: 1000,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children:[
                  const Text(
                    "Proof of Pick-up image",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(width: 50,),

                  GestureDetector(
                    onTap: () async {
                      var responseFromChooseImagePickUp = await chooseImageFromGalleryPickup();
                      log(responseFromChooseImagePickUp);
                      if(responseFromChooseImagePickUp == "done"){
                        var responseFromUploadImageToPickUp = await uploadImageToPickUp();
                        if(responseFromUploadImageToPickUp == "done"){
                          await setImageToDatabase();
                        }
                      }
                    },
                    child: pickupFile == null ?
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage("assets/images/avatarman.png"),
                    ) : Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey,
                        image: DecorationImage(
                          fit: BoxFit.fitHeight,
                          image: FileImage(
                            File(
                              pickupFile!.path,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                ]
              ),

              const Divider(
                height: 50,
                color: Colors.white,
              ),

              Row(
                children: [
                  const Text(
                    "Proof of Delivery image",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(width: 100,),

                  GestureDetector(
                    onTap: (){
                      chooseImageFromGalleryDestination();
                    },
                    child: destinationFile == null ?
                    const CircleAvatar(
                      radius: 50,
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
                              destinationFile!.path,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              )
            ]
          ),
        ),
      ),
    );
  }
}


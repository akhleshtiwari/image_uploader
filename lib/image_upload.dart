import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageUpload extends StatefulWidget {
  const ImageUpload({super.key});

  @override
  State<ImageUpload> createState() => _ImageUploadState();
}

class _ImageUploadState extends State<ImageUpload> {
  List<File> _images = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null) {
      setState(() {
        _images.addAll(pickedFiles.map((file) => File(file.path)).toList());
      });
      await _saveImages(_images);
    }
  }

  Future<void> _saveImages(List<File> images) async {
    final prefs = await SharedPreferences.getInstance();
    final directory = await getApplicationDocumentsDirectory();
    final imagePaths = await Future.wait(images.map((image) async {
      final imagePath = path.join(directory.path, path.basename(image.path));
      final savedImage = await image.copy(imagePath);
      return savedImage.path;
    }));

    // Store the image paths in SharedPreferences
    prefs.setStringList('imagePaths', imagePaths);
  }

  Future<void> _loadImages() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePaths = prefs.getStringList('imagePaths');

    if (imagePaths != null) {
      final imageFiles =
          imagePaths.map((imagePath) => File(imagePath)).toList();
      setState(() {
        _images = imageFiles;
      });
    }
  }

  void _deleteImage() {
    setState(() {
      _images.removeAt(_currentIndex);
      if (_images.isNotEmpty) {
        _currentIndex = _currentIndex % _images.length;
      } else {
        _currentIndex = 0;
      }
    });
  }

  void _viewImages(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 210, 209, 209),
          title: const Center(child: Text('Image Picker')),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _images.isEmpty
                    ? const Text('No images selected.')
                    : Column(
                        children: [
                          // Larger Carousel at the top
                          CarouselSlider.builder(
                            itemCount: _images.length,
                            itemBuilder: (context, index, realIndex) =>
                                GestureDetector(
                              onTap: () {
                                _viewImages(index);
                              },
                              child: Stack(
                                children: [
                                  PhotoViewGallery.builder(
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentIndex = index;
                                      });
                                    },
                                    scrollPhysics:
                                        const BouncingScrollPhysics(),
                                    pageController: PageController(
                                        initialPage: _currentIndex),
                                    backgroundDecoration: const BoxDecoration(
                                        color: Colors.white),
                                    itemCount: _images.length,
                                    builder: (context, index) =>
                                        PhotoViewGalleryPageOptions(
                                      minScale:
                                          PhotoViewComputedScale.contained,
                                      maxScale:
                                          PhotoViewComputedScale.covered * 2,
                                      imageProvider: FileImage(
                                        _images[_currentIndex],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 10,
                                    top: 10,
                                    child: IconButton(
                                        onPressed: _deleteImage,
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        )),
                                  ),
                                ],
                              ),
                            ),
                            options: CarouselOptions(
                              height: 400,
                              enlargeCenterPage: true,
                              onPageChanged: (index, reason) {
                                setState(() {
                                  _currentIndex = index;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Smaller Carousel below
                          CarouselSlider.builder(
                            itemCount: _images.length,
                            itemBuilder: (context, index, realIndex) =>
                                GestureDetector(
                              onTap: () {
                                _viewImages(index);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                    color: _currentIndex == index
                                        ? Colors.black
                                        : Colors.transparent),
                                padding: const EdgeInsets.all(2.0),
                                child: Image.file(
                                  _images[index],
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                ),
                              ),
                            ),
                            options: CarouselOptions(
                              height: 80,
                              enlargeCenterPage: false,
                              viewportFraction: 0.2,
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: const ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(Colors.white)),
                  onPressed: _pickImages,
                  child: const Text(
                    'Pick Images',
                    style: TextStyle(color: Colors.black),
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

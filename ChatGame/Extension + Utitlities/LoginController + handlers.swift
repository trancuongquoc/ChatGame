//
//  LoginController + handlers.swift
//  ChatGame
//
//  Created by Cuong on 9/10/18.
//  Copyright © 2018 quoccuong. All rights reserved.
//

import UIKit
import Firebase

// MARK: Handlers
extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc func handleLoginRegister() {
        if loginRegisterSegmentedControl.selectedSegmentIndex == 0 {
            handleLogin()
        } else {
            handleRegister()
        }
    }
    
    func handleLogin() {
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            print("Form invalid")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { (user, err) in
            if err != nil {
                print(err)
                return
            }
            self.messageController?.fetchUserAndSetNavBarTitle()
            
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    @objc func handleLoginRegisterChange() {
        let index = loginRegisterSegmentedControl.selectedSegmentIndex
        let title = loginRegisterSegmentedControl.titleForSegment(at: index)
        loginRegisterButton.setTitle(title, for: .normal)
        
        inputsContainerViewHeightAnchor?.constant = loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 100 : 150
        
        nameTextFieldHeightAnchor?.isActive = false
        nameTextFieldHeightAnchor = nameTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 0 : 1/3 )
        nameTextFieldHeightAnchor?.isActive = true
        
        emailTextFieldHeightAnchor?.isActive = false
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 1/2 : 1/3 )
        emailTextFieldHeightAnchor?.isActive = true
        
        passwordTextFieldHeightAnchor?.isActive = false
        passwordTextFieldHeightAnchor = passwordTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 1/2 : 1/3 )
        passwordTextFieldHeightAnchor?.isActive = true
    }
    
    @objc func handleRegister() {
        guard let email = emailTextField.text, let password = passwordTextField.text, let name = nameTextField.text else {
            print("Form is not valid")
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { user, error in
            if error != nil {
                print(error)
                return
            }
            
            guard let uid = user?.user.uid else { return }
            
            //Successfully authenticated user
            let imageName = NSUUID().uuidString
            
            let storageRef = Storage.storage().reference().child("profile_images").child("\(imageName).png")
            
            if let profileImage = self.profileImageView.image , let uploadData = UIImageJPEGRepresentation(profileImage, 0.1) {
                
                storageRef.putData(uploadData, metadata: nil, completion: { (metadata, err) in
                    
                    if err != nil {
                        print(err)
                        return
                    }
                    
                    storageRef.downloadURL(completion: { (url, err) in
                        
                        if err != nil {
                            print(err)
                            return
                        }
                        
                        if let downloadUrl = url?.absoluteString  {
                            let values = ["name": name, "email": email, "profileImageUrl": downloadUrl]
                            
                            self.saveUserIntoDatabaseWithUID(uid, values: values as [String : AnyObject])
                        }
                    })
                })
            }
        }
    }
    
    @objc func handleChoosingProfileImage() {
        let picker = UIImagePickerController()
        
        picker.delegate = self
        
        picker.allowsEditing = true
        
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage  {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            profileImageView.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("canceled picker.")
        dismiss(animated: true, completion: nil)
    }
}

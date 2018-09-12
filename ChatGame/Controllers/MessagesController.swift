//
//  ViewController.swift
//  ChatGame
//
//  Created by Cuong on 9/5/18.
//  Copyright © 2018 quoccuong. All rights reserved.
//

import UIKit
import Firebase

class MessagesController: UITableViewController, UIGestureRecognizerDelegate {
    
    let cellId = "cellid"
    
    var ref: DatabaseReference!
    
    var messages = [Message]()
    var messagesDictionary = [String: Message]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
        let planeImage = UIImage(named: "plane")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: planeImage, style: .plain, target: self, action: #selector(handleNewMessage))
        checkIfUserLoggedIn()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
//        observerMessages()
        observeUserMessages()
    }
    
    func observeUserMessages() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference().child("user-messages").child(uid)
        ref.observe(.childAdded) { (snapshot) in
            
            let messagesId = snapshot.key
            let messagesReference = Database.database().reference().child("messages").child(messagesId)
            
            messagesReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    
                    if let dictionary = snapshot.value as? [String: AnyObject] {
                        let message = Message()
                        message.fromId = dictionary["fromId"] as? String
                        message.text = dictionary["text"] as? String
                        message.timestamp = dictionary["timestamp"] as? NSNumber
                        message.toId = dictionary["toId"] as? String
                        
                        guard let chatPartnerId = message.fromId == uid ? message.toId : message.fromId else {
                            return
                        }
                        
                        if let toId = message.toId {
                            self.messagesDictionary[toId] = message
                            
                            self.messages = Array(self.messagesDictionary.values)
                            
                            self.messages.sort(by: { (message1, message2) -> Bool in
                                return (message1.timestamp?.intValue)! > (message2.timestamp?.intValue)!
                            })
                        }
                     
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
            }
        })
    }
}
    
    func observerMessages() {
        let ref = Database.database().reference().child("messages")
        ref.observe(.childAdded) { (snapshot) in
           
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let message = Message()
                message.fromId = dictionary["fromId"] as? String
                message.text = dictionary["text"] as? String
                message.timestamp = dictionary["timestamp"] as? NSNumber
                message.toId = dictionary["toId"] as? String
                self.messages.append(message)
                
                if let toId = message.toId {
                    self.messagesDictionary[toId] = message
                    
                    self.messages = Array(self.messagesDictionary.values)
                    
                    self.messages.sort(by: { (message1, message2) -> Bool in
                       return (message1.timestamp?.intValue)! > (message2.timestamp?.intValue)!
                    })
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                print(message.text)
            }
        }
    }

    
    @objc func handleNewMessage() {
        let newMessageController = NewMessageController()
        newMessageController.messagesController = self
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
        
    }
    
    func checkIfUserLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        } else {
           fetchUserAndSetNavBarTitle()
        }
    }
    
    func fetchUserAndSetNavBarTitle() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let user = User()
                user.name = dictionary["name"] as? String
                user.email = dictionary["email"] as? String
                user.profileImageUrl = dictionary["profileImageUrl"] as? String
                self.setupNavBarWithUser(user)
            }
            
        }, withCancel: nil)
    }
 
    lazy var titleView: UIView = {
        
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 200, height: 40)
        titleView.backgroundColor = UIColor.red
        let tap = UITapGestureRecognizer(target: self, action: #selector(showChatControllerForUser(_:)))
        titleView.addGestureRecognizer(tap)
        titleView.isUserInteractionEnabled = true
        
        return titleView
    }()
    
    lazy var profileImageView: UIImageView = {
        
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true

        return profileImageView
    }()
    
    lazy var nameLabel: UILabel = {
        
        let nameLabel = UILabel()
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false


        return nameLabel
    }()
    
    func setupNavBarWithUser(_ user: User) {

        if let profileImageUrl = user.profileImageUrl {
            profileImageView.loadImageUsingCacheWith(profileImageUrl)
        }

        titleView.addSubview(profileImageView)

        profileImageView.leftAnchor.constraint(equalTo: titleView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true

        nameLabel.text = user.name
        
        titleView.addSubview(nameLabel)
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: titleView.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true

        
        self.navigationItem.titleView = titleView
    }
    
    @objc func showChatControllerForUser(_ user: User) {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
    }
    
    @objc func handleLogout() {
        let loginController = LoginController()
        loginController.messageController = self
        present(loginController, animated: true, completion: nil)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension MessagesController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        
        let message = messages[indexPath.row]
        
        cell.message = message
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
}

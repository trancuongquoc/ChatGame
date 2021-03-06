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
    
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
        let planeImage = UIImage(named: "plane")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: planeImage, style: .plain, target: self, action: #selector(handleNewMessage))
        checkIfUserLoggedIn()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        tableView.allowsMultipleSelectionDuringEditing = true
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard let CurrentUserUid = Auth.auth().currentUser?.uid else {
            return
        }
        
        if let chatPartnerId = messages[indexPath.row].chatPartnerId() {
            Database.database().reference().child("user-messages").child(CurrentUserUid).child(chatPartnerId).removeValue { (error, ref) in
                
                if error != nil {
                    print("Failed to delete conversation.", error)
                    return
                }
                
                self.messagesDictionary.removeValue(forKey: chatPartnerId)
                self.attemptToReloadCollectionView()
            }
        }
    }
    
    
    
    func observeUserMessages() {
        guard let currentUserUID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference().child("user-messages").child(currentUserUID)
        
        ref.observe(.childAdded, with: { (snapshot) in
            let userId = snapshot.key
            
            Database.database().reference().child("user-messages").child(currentUserUID).child(userId).observe(.childAdded, with: { (snapshot) in

                let messageId = snapshot.key
                self.fetchMessage(with: messageId)
            })
            
        }, withCancel: nil)
        
        ref.observe(.childRemoved) { (snapshot) in
            self.messagesDictionary.removeValue(forKey: snapshot.key)
            self.attemptToReloadCollectionView()
        }
        
    }
    
    private func fetchMessage(with messageId: String) {
        let messagesReference = Database.database().reference().child("messages").child(messageId)
        
        messagesReference.observeSingleEvent(of: .value, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                
                let message = Message(dictionary: dictionary)
                
                if let chatPartnerId = message.chatPartnerId() {
                    self.messagesDictionary[chatPartnerId] = message
                }
                
                self.attemptToReloadCollectionView()
            }
        })
    }
    
    private func attemptToReloadCollectionView() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTableView), userInfo: nil, repeats: false)
    }
    
    @objc func handleReloadTableView() {
        
        self.messages = Array(self.messagesDictionary.values)
        
        self.messages.sort(by: { (message1, message2) -> Bool in
            return (message1.timestamp?.intValue)! > (message2.timestamp?.intValue)!
        })
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
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
                let user = User(dictionary: dictionary)
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
        
        messages.removeAll()
        messagesDictionary.removeAll()
        tableView.reloadData()
        
        observeUserMessages()
        
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        
        let chatPartnerId = message.chatPartnerId()
        
        let ref = Database.database().reference().child("users").child(chatPartnerId!)
        
        ref.observeSingleEvent(of: .value) { (snapshot) in
            
            guard let dictionary = snapshot.value as? [String: AnyObject] else {
                return
            }
            
            let user = User(dictionary: dictionary)
            user.id = snapshot.key
            self.showChatControllerForUser(user)
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
}

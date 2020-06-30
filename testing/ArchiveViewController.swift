//
//  ArchiveViewController.swift
//  testing
//
//  Created by Vadim on 17/03/2019.
//  Copyright © 2019 Vadim Zaripov. All rights reserved.
//

import UIKit
import Firebase

class ArchiveViewController: UIViewController{
    

    var frame: CGRect? = nil
    var bottom_bar_btns: [UIView] = []
    
    var current_tab = 0
    var views: [UIView] = [UIView(), UIView()]
    
    var bottom_bar = UIView()
    
    init(frame: CGRect)   {
        print("init nibName style")
        super.init(nibName: nil, bundle: nil)
        self.frame = frame
    }

    // note slightly new syntax for 2017
    required init?(coder aDecoder: NSCoder) {
        print("init coder style")
        super.init(coder: aDecoder)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(frame != nil){
            view.frame = frame!
        }
        let pd = 0.02*view.bounds.width
        bottom_bar = UIView(frame: CGRect(x: 0, y: 0.9*view.bounds.height, width: view.bounds.width, height: 0.1*view.bounds.height))
        for i in 0..<2{
            let width = view.bounds.width / 3
            let btn = UIButton(frame: CGRect(x: CGFloat(i+1)*pd + CGFloat(i)*width, y: pd, width: width, height: bottom_bar.bounds.height - 2*pd))
            btn.layer.borderWidth = 2
            btn.layer.borderColor = UIColor.white.cgColor
            btn.layer.cornerRadius = btn.bounds.height / 2
            btn.setTitle((i == 0) ? categories_title : archive_title, for: .normal)
            let f_sz = FontHelper().getFontSize(strings: [categories_title, archive_title], font: "Helvetica", maxFontSize: 120, width: 0.8*btn.bounds.width, height: 0.9*btn.bounds.height)
            btn.setTitleColor(UIColor.white, for: .normal)
            btn.titleLabel?.font = UIFont(name: "Helvetica", size: CGFloat(f_sz))
            btn.tag = i
            if(i == 0){
                btn.backgroundColor = UIColor.init(white: 1, alpha: 0.4)
            }
            btn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(switchView(gesture:))))
            bottom_bar.addSubview(btn)
            bottom_bar_btns.append(btn)
        }
        view.addSubview(bottom_bar)
        
        self.view.addSubview(views[0])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let subview = view.viewWithTag(10){
            subview.removeFromSuperview()
        }
        if let subview = view.viewWithTag(20){
            subview.removeFromSuperview()
        }
        let v = CustomTableView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - bottom_bar.bounds.height), content: categories_words)
        for cell in v.cells{
            cell.main_view.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(deleteCategory(gesture:))))
            cell.button_add.addTarget(self, action: #selector(learnCategory(sender:)), for: .touchUpInside)
            cell.button_share.addTarget(self, action: #selector(shareCategory(sender:)), for: .touchUpInside)
            for subcell in cell.subcells{
                subcell.0.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(learnWord(gesture:))))
            }
        }
        v.tag = 10
        views[0] = v
        
        let tableView = CustomTableView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - bottom_bar.bounds.height), content: archive)
        tableView.tag = 20
        views[1] = tableView
        if(current_tab == 0){
            view.addSubview(views[0])
        }else{
            view.addSubview(views[1])
        }
    }
    
    @objc func deleteCategory(gesture: UILongPressGestureRecognizer){
        if(gesture.state == .began){
            let alert = UIAlertController(title: delete_category_title, message: delete_category_description, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: alert_cancel, style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: alert_ok, style: .default, handler: { (action) in
                let cell = gesture.view?.superview as! CustomTableViewCell
                for w in cell.subcells{
                    let word = w.1
                    ref.child("words").child(String(word.db_index)).child("category").setValue(no_category)
                }
                let catInd = categories.firstIndex(of: cell.title)! - 1 - default_categories.count
                if(catInd >= 0){
                    let maxInd = (categories.count - 1 - default_categories.count) - 1
                    ref.child("categories").child(String(catInd)).setValue(categories.last!)
                    ref.child("categories").child(String(maxInd)).removeValue()
                    print(cell.title, categories.firstIndex(of: cell.title)!)
                    print(categories)
                    categories.remove(at: categories.firstIndex(of: cell.title)!)
                    print(categories)
                }
                categories_words.removeValue(forKey: cell.title)
                self.viewWillAppear(false)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func shareCategory(sender: UIButton){
        let cell = sender.superview?.superview as! CustomTableViewCell
        let category_text = cell.title
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.athene.xenous.ru"
        components.path = "/category"
        
        let userIdQueryItem = URLQueryItem(name: "user", value: Auth.auth().currentUser!.uid)
        let categoryQueryItem = URLQueryItem(name: "category", value: category_text)
        
        components.queryItems = [userIdQueryItem, categoryQueryItem]
        
        guard let linkParameter = components.url else {return}
        print("Sharing \(linkParameter.absoluteString)")
        
        //Actual link
        guard let shareLink = DynamicLinkComponents.init(link: linkParameter, domainURIPrefix: "https://athene.page.link") else {
            print("Couldn't create FDL components")
            return
        }
        
        if let bundleID = Bundle.main.bundleIdentifier{
            shareLink.iOSParameters = DynamicLinkIOSParameters(bundleID: bundleID)
        }
        shareLink.iOSParameters?.appStoreID = "1487762033"
        
        shareLink.androidParameters = DynamicLinkAndroidParameters(packageName: "com.develop.vadim.english")
        
        shareLink.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        shareLink.socialMetaTagParameters?.title = "Кажется кто-то хочет поделиться с вами списком слов в приложении Athene!"
        shareLink.socialMetaTagParameters?.descriptionText = "Скачайте Athene, чтобы получить доступ к списку слов."
        
        guard let longURL = shareLink.url else {return}
        print("Long url: \(longURL)")
        
        shareLink.shorten { [weak self] (url, warnings, error) in
            if let error = error{
                print("Error while shortening url: \(error.localizedDescription)")
                return
            }
            if let warnings = warnings{
                for warning in warnings{
                    print("Warning: \(warning)")
                }
            }
            guard let url = url else {return}
            print("Shortened url: \(url.absoluteString)")
            self?.showShareSheet(url: url)
        }
        
    }
    
    func showShareSheet(url: URL){
        let promoText = promo_text
        let activityVC = UIActivityViewController(activityItems: [promoText, url], applicationActivities: nil)
        present(activityVC, animated: true)
    }
    
    @objc func learnCategory(sender: UIButton){
        let cell = sender.superview?.superview as! CustomTableViewCell
        var k = 0
        let n = cell.subcells.count
        for i in cell.subcells{
            let word = i.1
            if(word.level == -2){
                k += 1
            }
        }
        let alert = UIAlertController(
            title: add_alert_title[0] + String(k) + add_alert_title[1] + String(n) + add_alert_title[2],
            message: add_alert_describtion,
            preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: alert_yes, style: UIAlertAction.Style.default, handler: {(action) in
            for i in cell.subcells{
                let word = i.1
                if(word.level == -2){
                    ref.child("words").child(word.db_index).child("level").setValue(0)
                    ref.child("words").child(word.db_index).child("date").setValue(next_date.toDatabaseFormat())
                }
            }
        }))
        
        alert.addAction(UIAlertAction(title: alert_cancel, style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func learnWord(gesture: UILongPressGestureRecognizer){
        if(gesture.state == .began){
            let cell = gesture.view?.superview as! CustomTableViewCell
            let ind = gesture.view?.tag
            let word = cell.subcells[ind!].1
            if(word.level == -2){
                let alert = UIAlertController(title: add_alert_title_single, message: add_alert_describtion_single, preferredStyle: .actionSheet)
                
                alert.addAction(UIAlertAction(title: alert_yes, style: UIAlertAction.Style.default, handler: {(action) in
                    ref.child("words").child(word.db_index).child("level").setValue(0)
                    ref.child("words").child(word.db_index).child("date").setValue(next_date.toDatabaseFormat())
                }))
                
                alert.addAction(UIAlertAction(title: alert_cancel, style: .default, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
            }else{
                let alert = UIAlertController(
                    title: already_learning_word_message,
                    message: already_learning_word_description,
                    preferredStyle: .actionSheet)
                self.present(alert, animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
                    alert.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    @objc func switchView(gesture: UITapGestureRecognizer){
        let new_ind = gesture.view!.tag
        print(current_tab, new_ind)
        if(new_ind == current_tab){
            return
        }
        view.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.3, animations: {
            self.views[self.current_tab].alpha = 0
            for i in self.bottom_bar_btns{i.backgroundColor = UIColor.init(white: 1, alpha: 0.2)}
        }, completion: {(finished: Bool) in
            self.views[new_ind].alpha = 0
            self.view.addSubview(self.views[new_ind])
            self.views[self.current_tab].removeFromSuperview()
            UIView.animate(withDuration: 0.3, animations: {
                self.views[new_ind].alpha = 1
                self.bottom_bar_btns[self.current_tab].backgroundColor = UIColor.clear
                self.bottom_bar_btns[new_ind].backgroundColor = UIColor.init(white: 1, alpha: 0.4)
            }, completion: {(finished: Bool) in
                self.current_tab = new_ind
                self.view.isUserInteractionEnabled = true
            })
        })
    }
}

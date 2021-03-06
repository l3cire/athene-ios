//
//  MainViewController.swift
//  testing
//
//  Created by Vadim on 28/03/2020.
//  Copyright © 2020 Vadim Zaripov. All rights reserved.
//

import Foundation
import UIKit
import os
import Firebase

var main_vc = MainViewController()
var currentPageIndex:Int = 1

class MainViewController: UIViewController, UIPageViewControllerDataSource, UINavigationControllerDelegate, UIPageViewControllerDelegate, UIScrollViewDelegate {
    
    
    var cheerView: SAConfettiView!
    @IBOutlet weak var sign_out_btn: Button!
    @IBOutlet weak var btn_top_constraint: NSLayoutConstraint!
    @IBOutlet weak var pager_view: CustomPageControl!
    @IBOutlet weak var main_v: UIView!
    
    var pageviewcontroller:UIPageViewController! // self explanatory
    var ViewControllers: [UIViewController] = [UIViewController]()
    
    let dateFormatter = DateFormatter()
    
    var lastPendingViewControllerIndex = 0
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = ViewControllers.index(of: viewController) else {
            return nil
        }
        let previousIndex = viewControllerIndex - 1
        guard previousIndex >= 0 else {
            return nil
        }
        guard ViewControllers.count > previousIndex else {
            return nil
        }
        return ViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = ViewControllers.index(of: viewController) else {
            return nil
        }
        let previousIndex = viewControllerIndex + 1
        guard previousIndex >= 0 else {
            return nil
        }
        guard ViewControllers.count > previousIndex else {
            return nil
        }
        return ViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]){
        cheerView.stopConfetti()
        if pendingViewControllers.count > 0 {
            lastPendingViewControllerIndex = ViewControllers.index(of: pendingViewControllers.first!)!
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed{
            lastPendingViewControllerIndex = currentPageIndex
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        main_vc = self
    }
    
    var was_layout_set = false
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if(was_layout_set){return}
        cheerView = SAConfettiView(frame: view.bounds)
        view.addSubview(cheerView)
        view.sendSubviewToBack(cheerView)
        view.sendSubviewToBack(view.viewWithTag(911)!)
        cheerView.intensity = 0.7
        
        was_layout_set = true
        pager_view.set(width: self.view.frame.width, height: 0.05*self.view.frame.height, tabs: 3, start: currentPageIndex, color: UIColor.white)
        
        let padding = 0.02*view.bounds.height
        btn_top_constraint.constant = padding
        self.pageviewcontroller = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        self.pageviewcontroller.dataSource = self
        self.pageviewcontroller.delegate = self
        
        self.pageviewcontroller.view.frame = CGRect(x: 0, y: 0, width: main_v.bounds.width, height: 0.97*main_v.bounds.height)
        self.pageviewcontroller.view.center = main_v.center

        ViewControllers.append(ArchiveViewController(frame: CGRect(x: 0, y: 0, width: self.pageviewcontroller.view.bounds.width, height: self.pageviewcontroller.view.bounds.height)))
        ViewControllers.append(ViewController(frame: CGRect(x: 0, y: 0, width: self.pageviewcontroller.view.bounds.width, height: self.pageviewcontroller.view.bounds.height)))
        ViewControllers.append(NewWordViewController(frame: CGRect(x: 0, y: 0, width: self.pageviewcontroller.view.bounds.width, height: self.pageviewcontroller.view.bounds.height)))
        self.pageviewcontroller.setViewControllers([ViewControllers[currentPageIndex]], direction: .forward, animated: true, completion: nil)
        
        self.addChild(self.pageviewcontroller)
        self.view.addSubview(self.pageviewcontroller.view)
        self.pageviewcontroller.didMove(toParent: self)
        
        for subview in self.pageviewcontroller.view.subviews {
            if let scrollView = subview as? UIScrollView {
                scrollView.delegate = self
            }
        }
        
        if let loading_v = view.viewWithTag(54321){
            view.bringSubviewToFront(loading_v)
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if(currentPageIndex == lastPendingViewControllerIndex) {return}
        let point = scrollView.contentOffset
        var percentComplete: CGFloat
        percentComplete = abs(point.x - view.frame.size.width)/view.frame.size.width
        if(percentComplete >= 0 && percentComplete <= 1){
            pager_view.updateState(from: currentPageIndex, to: lastPendingViewControllerIndex, progress: percentComplete)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if(UserDefaults.isFirstLaunch()){
            DispatchQueue.main.async(){
                self.performSegue(withIdentifier: "move_to_tutorial", sender: self)
            }
            return
        }
        if(Auth.auth().currentUser == nil){
            DispatchQueue.main.async(){
                self.performSegue(withIdentifier: "signing_out", sender: self)
            }
            return
        }
        if let storedDynamicLink = UserDefaults.standard.url(forKey: "StoredDynamicLink"){
            self.view.layoutIfNeeded()
            UserDefaults.standard.removeObject(forKey: "StoredDynamicLink")
            print("GETTING SAVED DYNAMIC LINK: \(storedDynamicLink)")
            handleIncomingDynamicLink(storedDynamicLink, v_controller: self)
        }
        user = Auth.auth().currentUser!
        var loadingView = LoadingView()
        if view.viewWithTag(54321) != nil{
            loadingView = view.viewWithTag(54321) as! LoadingView
            view.bringSubviewToFront(loadingView)
            loadingView.show()
        } else {
            loadingView.tag = 54321
            loadingView.set(frame: view.frame)
            view.addSubview(loadingView)
            view.bringSubviewToFront(loadingView)
            loadingView.show()
        }
        updateWordsFromDatabase(completion: {(finished: Bool) in
            loadingView.removeFromSuperview()
            if(currentPageIndex == 1){
                (self.ViewControllers[1] as! ViewController).checkWordsUpdate()
            }else if(currentPageIndex == 2){
                (self.ViewControllers[2] as! NewWordViewController).initialSetting()
            }
        })
    }

    @IBAction func logOut(_ sender: Any) {
        let alert = UIAlertController(title: sign_out_question, message: nil, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: sign_out_text, style: UIAlertAction.Style.default, handler: {(action) in
            let firebaseAuth = Auth.auth()
            do {
                try firebaseAuth.signOut()
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "signing_out", sender: self)
                }
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
        }))
        alert.addAction(UIAlertAction(title: sign_out_cancel, style: UIAlertAction.Style.default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
}

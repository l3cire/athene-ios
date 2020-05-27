//
//  ChangeWordViewController.swift
//  testing
//
//  Created by Vadim on 16/03/2019.
//  Copyright © 2019 Vadim Zaripov. All rights reserved.
//

import UIKit
import os

class ChangeWordViewController: NewWordViewController {
    
    override func initialSetting() {
        mainView = ChangeWordView(frame: view.bounds, categories: categories)
        mainView.tag = 12345
        view.addSubview(mainView)
        setView()
    }
    
    override func setView() {
        super.setView()
        ed_text_english.text = words[0].english
        ed_text_russian.text = words[0].russian
        mainView.categoryLabel.text = words[0].category
        let cancel_btn = view.viewWithTag(801) as! UIButton
        cancel_btn.addTarget(self, action: #selector(cancel(_:)), for: .touchUpInside)
    }
    
    override func submit(_ sender: Any) {
        guard let eng = ed_text_english.text?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        guard let rus = ed_text_russian.text?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        ref.child("words").child(String(words[0].db_index)).child("English").setValue(eng)
        ref.child("words").child(String(words[0].db_index)).child("Russian").setValue(rus)
        ref.child("words").child(String(words[0].db_index)).child("category").setValue(mainView.categoryLabel.text!)
        
        performSegue(withIdentifier: "back_from_word_edit", sender: self)
    }
    
    @objc func cancel(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "back_from_word_edit", sender: self)
    }

}

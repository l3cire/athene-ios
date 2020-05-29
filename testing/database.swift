//
//  database.swift
//  testing
//
//  Created by Vadim Zaripov on 29.05.2020.
//  Copyright © 2020 Vadim Zaripov. All rights reserved.
//

import Foundation
import Firebase

var russian_list: [String] = []
var english_list: [String] = []

func updateWordsFromDatabase(completion: ((Bool) -> Void)?){
    user_id = Auth.auth().currentUser!.uid
    var _archive: [Word] = []
    var _words: [Word] = []
    var _russian_list: [String] = []
    var _english_list: [String] = []
    var _categories_words: [String: [Word]] = [:]
    var _categories: [String] = [no_category] + default_categories
    number_of_words = 0
    SetDates()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    ref = Database.database().reference().child("users").child(user_id)
    ref.observeSingleEvent(of: .value, with: { (snp) in
        let en = snp.childSnapshot(forPath: "categories").children
        while let snap = en.nextObject() as? DataSnapshot{
            _categories.append(snap.value as! String)
        }
        let snapshot = snp.childSnapshot(forPath: "words")
        number_of_words = Int(snapshot.childrenCount)
        var date: Date, count: Int
        let enumerator = snapshot.children
        while let snap = enumerator.nextObject() as? DataSnapshot{
            date = Date(milliseconds: snap.childSnapshot(forPath: "date").value as? Int64 ?? 0)
            count = Calendar.current.dateComponents([.day], from: date, to: now_date).day!
            let eng = snap.childSnapshot(forPath: "English").value as? String ?? ""
            let rus = snap.childSnapshot(forPath: "Russian").value as? String ?? ""
            let category = snap.childSnapshot(forPath: "category").value as? String ?? ""
            var level = snap.childSnapshot(forPath: "level").value as? Int ?? 0
            _russian_list.append(rus)
            _english_list.append(eng)
            if(category != no_category){
                if(_categories_words[category] != nil){
                    _categories_words[category]!.append(Word(eng: eng, rus: rus, ct: category, lvl: level, ind: Int(snap.key)!))
                }else{
                    _categories_words[category] = [Word(eng: eng, rus: rus, ct: category, lvl: level, ind: Int(snap.key)!)]
                }
            }
            if(level == -1){
                _archive.append(Word(eng: eng, rus: rus, ct: category, lvl: -1, ind: Int(snap.key)!))
            }else if(level != -2 && count > 0){
                ref.child("words").child(snap.key).child("date").setValue(now_date.toDatabaseFormat())
                if(count >= 3 && (level == 1 || level == 2)){
                    level = 0
                }
                ref.child("words").child(snap.key).child("level").setValue(level)
                _words.append(Word(eng: eng, rus: rus, ct: category, lvl: level, ind: Int(snap.key)!))
            }else if(level != -2 && count == 0){
                _words.append(Word(eng: eng, rus: rus, ct: category, lvl: level, ind: Int(snap.key)!))
            }
        }
        archive = _archive
        words = _words
        russian_list = _russian_list
        english_list = _english_list
        categories_words = _categories_words
        categories = _categories
        if let comp = completion{
            comp(true)
            for i in categories_words{
                for j in i.value{
                    print(j.english, terminator: " ")
                }
            }
        }
    })
}

func downloadCategory(completion: ((Bool) -> Void)?){
    guard let category = category_shared else {return}
    guard let id = user_shared_id else {return}
    updateWordsFromDatabase(completion: {(finished: Bool) in
        if(!categories.contains(category)){
            ref.child("categories").child(String(categories.count - default_categories.count - 1)).setValue(category)
            categories.append(category)
        }
        let other_user_ref = Database.database().reference().child("users").child(id)
        other_user_ref.child("words").observeSingleEvent(of: .value, with: {(snapshot) in
            let enumerator = snapshot.children
            while let snap = enumerator.nextObject() as? DataSnapshot{
                let eng = snap.childSnapshot(forPath: "English").value as? String ?? ""
                let rus = snap.childSnapshot(forPath: "Russian").value as? String ?? ""
                let cat = snap.childSnapshot(forPath: "category").value as? String ?? ""
                if(english_list.contains(eng) || russian_list.contains(rus)){continue}
                if(cat.elementsEqual(category)){
                    ref.child("words").child(String(number_of_words)).child("English").setValue(eng)
                    ref.child("words").child(String(number_of_words)).child("Russian").setValue(rus)
                    ref.child("words").child(String(number_of_words)).child("category").setValue(cat)
                    ref.child("words").child(String(number_of_words)).child("level").setValue(-2)
                    ref.child("words").child(String(number_of_words)).child("date").setValue(now_date.toDatabaseFormat())
                    if(categories_words[category] != nil){
                        categories_words[category]!.append(Word(eng: eng, rus: rus, ct: category, lvl: -2, ind: number_of_words))
                    }else{
                        categories_words[category] = [Word(eng: eng, rus: rus, ct: category, lvl: -2, ind: number_of_words)]
                    }
                    number_of_words += 1
                }
            }
            if let comp = completion{
                comp(true)
                print(words.count)
            }
        })
    })
}
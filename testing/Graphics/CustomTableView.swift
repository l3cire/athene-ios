//
//  CustomTableView.swift
//  testing
//
//  Created by Vadim on 06/04/2020.
//  Copyright © 2020 Vadim Zaripov. All rights reserved.
//

import Foundation
import UIKit

class CustomTableView: UIScrollView {
    
    var content: [String: [Word]] = [:]
    var cells: [CustomTableViewCell] = []
    
    var padding: CGFloat = 0
    var cellHeight: CGFloat = 0
    
    init(frame: CGRect, content: [String: [Word]]){
        super.init(frame: frame)
        self.content = content
        
        
        self.padding = 0.03*frame.width
        
        var y = padding
        var tg = 0
        
        for i in content.keys{
            let cell = CustomTableViewCell(frame: CGRect(x: 0, y: 0, width: frame.width - 2*padding, height: 0.1*frame.height), text: i)
            cell.center = CGPoint(x: frame.width / 2, y: y + cell.bounds.height / 2)
            cell.tag = tg
            tg += 1
            y += cell.bounds.height + padding
            self.addSubview(cell)
            for j in content[i]!{
                cell.createSubcell(word: j)
            }
            cell.main_view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onCellPressed(sender:))))
            cells.append(cell)
        }
    }
    
    @objc func onCellPressed(sender: UITapGestureRecognizer){
        let cell = sender.view?.superview as! CustomTableViewCell
        let pos = cell.tag
        var move_by = cell.opened_resize
        UIView.animate(withDuration: 0.4, animations: {
            if(cell.opened){
                self.cells[pos].shrink()
                move_by *= -1
            }else{
                self.cells[pos].expand()
            }
            for i in (pos+1)..<self.cells.count{
                self.cells[i].move(by_y: move_by)
            }
            self.contentSize.height = self.cells.last!.frame.maxY + self.padding
        })
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

class CustomTableViewCell: UIView{
       
    var subcells: [(UIView, Word)] = []
    var opened_resize: CGFloat = 0
    var opened = false
    
    var main_view = UIView()
    var triangle = UIImageView()
    
    let font = "Helvetica"
    var padding: CGFloat = 0
       
    init(frame: CGRect, text: String) {
        super.init(frame: frame)
        padding = 0.15*frame.height
        
        main_view = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        main_view.layer.cornerRadius = min(frame.width, frame.height) / 2
        main_view.backgroundColor = UIColor.init(white: 1, alpha: 0.4)
        main_view.layer.borderWidth = 2
        main_view.layer.borderColor = UIColor.white.cgColor
        
        triangle = UIImageView(frame: CGRect(x: 0, y: 0, width: 0.3*frame.height, height: 0.2*frame.height))
        triangle.image = UIImage(named: "polygon")!.withRenderingMode(.alwaysTemplate)
        triangle.tintColor = UIColor.white
        triangle.center = CGPoint(x: main_view.bounds.width - main_view.layer.cornerRadius - triangle.bounds.width / 2, y: main_view.bounds.height / 2)
        main_view.addSubview(triangle)
        
        let t_view = UILabel(frame: CGRect(x: main_view.layer.cornerRadius, y: 0, width: triangle.frame.minX - main_view.layer.cornerRadius, height: main_view.bounds.height))
        let f_sz = CGFloat(FontHelper().getInterfaceFontSize(font: font, height: 0.7*main_view.bounds.height))
        t_view.font = UIFont(name: font, size: f_sz)
        t_view.textColor = UIColor.white
        t_view.text = text
        t_view.baselineAdjustment = .alignCenters
        main_view.addSubview(t_view)
        
        self.addSubview(main_view)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func createSubcell(word: Word){
        let view = UIView()
        view.tag = subcells.count
        view.bounds = CGRect(x: 0, y: 0, width: 0.8*main_view.bounds.width, height: main_view.bounds.height)
        view.center = main_view.center
        view.alpha = 0
        view.backgroundColor = UIColor.init(white: 1, alpha: 0.4)
        view.layer.borderWidth = 2
        view.layer.cornerRadius = view.bounds.height / 2
        view.layer.borderColor = UIColor.white.cgColor
        let t_view = UILabel(frame: CGRect(x: view.layer.cornerRadius, y: 0, width: view.bounds.width - 2*view.layer.cornerRadius, height: view.bounds.height))
        let f_sz = CGFloat(FontHelper().getInterfaceFontSize(font: font, height: 0.7*view.bounds.height))
        t_view.font = UIFont(name: font, size: f_sz)
        t_view.textColor = UIColor.white
        t_view.text = word.english
        t_view.baselineAdjustment = .alignCenters
        t_view.tag = -1
        view.addSubview(t_view)
        
        self.addSubview(view)
        self.sendSubviewToBack(view)
        subcells.append((view, word))
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(show(gesture:))))
        
        opened_resize += view.bounds.height + padding
    }
       
    @objc func show(gesture: UITapGestureRecognizer){
        gesture.view!.isUserInteractionEnabled = false
        let label = gesture.view?.viewWithTag(-1) as! UILabel
        let word = subcells[gesture.view!.tag].1
        flip(label: label, text: word.russian, completion: {(finished: Bool) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self.flip(label: label, text: word.english, completion: {(finished: Bool) in
                    gesture.view!.isUserInteractionEnabled = true
                })
            })
        })
    }
    
    func flip(label: UILabel, text: String, completion: ((Bool) -> Void)?){
        UIView.animate(withDuration: 0.3, animations: {
            label.alpha = 0
        }, completion: {(finished: Bool) in
            label.text = text
            UIView.animate(withDuration: 0.3, animations: {
                label.alpha = 1
            }, completion: completion)
        })
    }
       
    func expand(){
        opened = true
        let tr = CGAffineTransform.identity.rotated(by: CGFloat(Double.pi))
        triangle.transform = tr
        self.frame = CGRect(x: self.frame.minX, y: self.frame.minY, width: self.frame.width, height: self.frame.height + opened_resize)
        var y = main_view.frame.maxY + padding
        for i in subcells{
            i.0.alpha = 1
            i.0.center = CGPoint(x: i.0.center.x, y: y + i.0.bounds.height / 2)
            y += padding + i.0.bounds.height
        }
    }
       
    func shrink(){
        opened = false
        let tr = CGAffineTransform.identity.rotated(by: 0)
        triangle.transform = tr
        self.frame = CGRect(x: self.frame.minX, y: self.frame.minY, width: main_view.frame.width, height: main_view.frame.height)
        for i in subcells{
            i.0.alpha = 0
            i.0.center = main_view.center
        }
    }
       
    func move(by_y y: CGFloat){
        self.center = CGPoint(x: self.center.x, y: self.center.y + y)
    }
   }
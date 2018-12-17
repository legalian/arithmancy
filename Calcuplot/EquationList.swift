//
//  EquationList.swift
//  Calcuplot
//
//  Created by Parker on 10/30/18.
//  Copyright © 2018 Parker. All rights reserved.
//

import Foundation

class EquationCellController: UITableViewCell,MTEditableMathLabelDelegate {
    @IBOutlet var mathLabel : MTEditableMathLabel!
    @IBOutlet var colorLabel : MTEditableMathLabel!


    func textModified(_ label:MTEditableMathLabel) {
        if (label===mathLabel) {
        
        } else if (label===colorLabel) {
        
        }
    }
    func didEndEditing(_ label:MTEditableMathLabel) {
        if (label===mathLabel) {
//            print(mathLabel.mathList.stringValue)
            parse(mathLabel.mathList.atoms)
            
        } else if (label===colorLabel) {
        
        }
    }

    var loaded=false;
    override func layoutSubviews() {
        super.layoutSubviews()
        if (!self.loaded) {
            self.loaded=true
            self.mathLabel.fontSize = 15
            self.mathLabel.layer.borderColor = UIColor.black.cgColor
            self.mathLabel.layer.borderWidth = 2
            self.mathLabel.layer.cornerRadius = 5
            self.mathLabel.keyboard = MTMathKeyboardRootView.sharedInstance()
            self.mathLabel.delegate = self as MTEditableMathLabelDelegate
            self.mathLabel.enableTap(true)
            
            self.colorLabel.fontSize = 15
            self.colorLabel.layer.borderColor = UIColor.black.cgColor
            self.colorLabel.layer.borderWidth = 2
            self.colorLabel.layer.cornerRadius = 5
            self.colorLabel.keyboard = MTMathKeyboardRootView.sharedInstance()
            self.colorLabel.delegate = self as MTEditableMathLabelDelegate
            self.colorLabel.enableTap(true)
        }
    }
    
}
//class EquationTableController : UITableViewController {
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//
//    }
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//
//    }
//}


//
class EquationListController: UIViewController,UITableViewDataSource,UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "enterfunctor", for: indexPath) as! EquationCellController
//         cell.textLabel?.text = "test"
         return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 186;
    }
    
//    @IBOutlet var mathLabel : MTEditableMathLabel!
    @IBOutlet var UIFunctions : UITableView!
    
//    var functlets = [String]()
//    var newCar: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        functlets = [""]
        
//        self.mathLabel.layer.borderColor = UIColor.black.cgColor
//        self.mathLabel.layer.borderWidth = 2
//        self.mathLabel.layer.cornerRadius = 5
//        var doo = MTMathKeyboardRootView.sharedInstance()
//        self.mathLabel.keyboard = doo
//        self.mathLabel.delegate = self as MTEditableMathLabelDelegate
//        self.mathLabel.enableTap(true)
    }


}




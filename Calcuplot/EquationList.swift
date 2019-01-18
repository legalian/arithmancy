//
//  EquationList.swift
//  Calcuplot
//
//  Created by Parker on 10/30/18.
//  Copyright © 2018 Parker. All rights reserved.
//

import Foundation
import iosMath

func startlabel(_ mathLabel : MTEditableMathLabel,_ delegate : MTEditableMathLabelDelegate) {
    mathLabel.fontSize = 15
    mathLabel.layer.borderColor = UIColor.black.cgColor
    mathLabel.layer.borderWidth = 2
    mathLabel.layer.cornerRadius = 5
    mathLabel.keyboard = MTMathKeyboardRootView.sharedInstance()
    mathLabel.delegate = delegate
    mathLabel.enableTap(true)
}

class EquationCellController: UITableViewCell,MTEditableMathLabelDelegate {
    @IBOutlet var mathLabel : MTEditableMathLabel!
    @IBOutlet var colorLabel : MTEditableMathLabel!
    @IBOutlet var selector : UISegmentedControl!
    
    var elc : EquationListController? = nil
    var ind : Int = 0
    func textModified(_ label:MTEditableMathLabel) {
        elc?.equations[ind] = CellData(mathLabel.mathList,colorLabel.mathList,selector.selectedSegmentIndex)
    }
    @objc func textFieldDidChange(_ sender: UITextField) {
        elc?.equations[ind] = CellData(mathLabel.mathList,colorLabel.mathList,selector.selectedSegmentIndex)
    }
    func didEndEditing(_ label:MTEditableMathLabel) {
        print(label.mathList.stringValue)
        let vog = parse(label.mathList.atoms)
        switch vog {
            case .scalar(let a): print(a.latex())
            case .vector2(let a): print(a.latex())
            case .vector3(let a): print(a.latex())
            default: print("ERROR")
        }
    }
}

class CellData {
    var function: MTMathList
    var color: MTMathList
    var parsedfunc: MathStruct
    var parsedcolor: MathStruct
    var selector: Int
    init(_ f:MTMathList,_ c:MTMathList,_ i:Int) {function = f;color = c;selector = i;parsedfunc = parse(function.atoms);parsedcolor = parse(color.atoms);}
    init() {function = MTMathList();color = MTMathList();selector = 1;parsedcolor = .error;parsedfunc = .error}
}



class EquationListController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    @IBOutlet var strongref : UITableView!
    var equations: [CellData] = []
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {return equations.count+1}
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == equations.count {return tableView.dequeueReusableCell(withIdentifier: "addnewcell")!}
        let cell = tableView.dequeueReusableCell(withIdentifier: "enterfunctor") as! EquationCellController
        cell.mathLabel.mathList  = equations[indexPath.row].function
        cell.colorLabel.mathList = equations[indexPath.row].color
        cell.selector.selectedSegmentIndex = equations[indexPath.row].selector
        cell.elc = self
        cell.ind = indexPath.row
        startlabel(cell.mathLabel,cell)
        startlabel(cell.colorLabel,cell)
        cell.selector.addTarget(cell, action: #selector(cell.textFieldDidChange), for: .editingChanged)
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == equations.count {return 60}
        return 168
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == equations.count {
            equations.append(CellData())
            tableView.beginUpdates()
            tableView.insertRows(at: [IndexPath.init(row: equations.count-1, section: 0)], with: .automatic)
            tableView.endUpdates()
        }
    }
}



class ScratchpadEntry: UITableViewCell {
    @IBOutlet var call : MTMathUILabel!
    @IBOutlet var response : MTMathUILabel!    
}




class ScratchpadListController: UIViewController,UITableViewDataSource,UITableViewDelegate,MTEditableMathLabelDelegate {
    @IBOutlet var strongref : UITableView!
    @IBOutlet var mathLabel : MTEditableMathLabel!
    @IBOutlet weak var spacerBottomLayoutConstraint: NSLayoutConstraint!
    
    weak var equations : EquationListController? = nil
    
    var questions : [MTMathList] = []
    var answers : [String] = []

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {return answers.count;}
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "scratchrow", for: indexPath) as! ScratchpadEntry
        cell.call.mathList = questions[indexPath.row]
        cell.response.latex = answers[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80;
    }
    func returnPressed(_ label: MTEditableMathLabel!) {
        questions.append(label.mathList)
        let vog = parse(label.mathList.atoms)
        switch vog {
            case .scalar(let a):
            answers.append(a.latex())
            case .vector2(let a): answers.append(a.latex())
            case .vector3(let a): answers.append(a.latex())
            default: answers.append("ERROR")
        }
        strongref.beginUpdates()
        strongref.insertRows(at: [IndexPath.init(row: answers.count-1, section: 0)], with: .automatic)
        strongref.endUpdates()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        startlabel(mathLabel,self)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardUpdate), name:UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardUpdate), name:UIResponder.keyboardWillHideNotification, object: nil)
    }
    @objc func keyboardUpdate(_ notification: NSNotification) {
        let userInfo = notification.userInfo!
        let animationDuration: TimeInterval = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        let animationCurve = UIView.AnimationOptions(rawValue:(userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).uintValue)
        let keyboardViewBeginFrame = view.convert(userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! CGRect, from: view.window)
        let keyboardViewEndFrame   = view.convert(userInfo[UIResponder.keyboardFrameEndUserInfoKey]   as! CGRect, from: view.window)
        spacerBottomLayoutConstraint?.constant = CGFloat(keyboardViewBeginFrame.origin.y>keyboardViewEndFrame.origin.y ? keyboardViewEndFrame.height : 0)
        view.setNeedsLayout()
        let animationOptions: UIView.AnimationOptions = [animationCurve, .beginFromCurrentState]
        UIView.animate(withDuration: animationDuration, delay: 0, options: animationOptions, animations: {self.view.layoutIfNeeded()}, completion: nil)
    }
}










class MenuTabsView: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    func newVc(viewController: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: viewController)
    }
    lazy var orderedViewControllers: [UIViewController] = {
        let gez = [self.newVc(viewController: "graphs"),
                self.newVc(viewController: "memory"),
                self.newVc(viewController: "scratchpad")]
        (gez[0] as! GraphingView).equations = (gez[1] as! EquationListController)
        (gez[2] as! ScratchpadListController).equations = (gez[1] as! EquationListController)
        return gez
    }()
    func pageViewController(_ _: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        var ind = orderedViewControllers.index(of: viewController)!
        ind = (ind-1)%%3
        if let gra = orderedViewControllers[ind] as? GraphingView {gra.updateGraphs()}
        return orderedViewControllers[ind]
    }
    func pageViewController(_ _: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        var ind = orderedViewControllers.index(of: viewController)!
        ind = (ind+1)%%3
        if let gra = orderedViewControllers[ind] as? GraphingView {gra.updateGraphs()}
        return orderedViewControllers[ind]
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        setViewControllers([orderedViewControllers[1]],
                           direction: .forward,
                           animated: true,
                           completion: nil)
    }
}


































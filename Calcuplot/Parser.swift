//
//  Parser.swift
//  Calcuplot
//
//  Created by Parker on 12/15/18.
//  Copyright © 2018 Parker. All rights reserved.
//

import Foundation



enum MathStruct {
    case scalar(Scalar)
    case vector2(Vector2)
    case vector3(Vector3)
    case error
}

func *(_ a:MathStruct,_ b:MathStruct) -> MathStruct {
    switch (a,b) {
        case (.scalar(let a),.scalar(let b)): return .scalar(a*b)
        case (.scalar(let a),.vector2(let b)): return .vector2(ScalarProd2(a,b))
        case (.scalar(let a),.vector3(let b)): return .vector3(ScalarProd3(a,b))
        case (.vector2(let a),.scalar(let b)): return .vector2(ScalarProd2(b,a))
        case (.vector3(let a),.scalar(let b)): return .vector3(ScalarProd3(b,a))
        default: return .error
    }
}


func parseuntil(_ tokens: [MTMathAtom],_ j:inout Int,_ m:Int,_ delim:String) -> MathStruct {
    j=j+1
    for g in j..<m {if delim == tokens[g].nucleus {let u=j;j=g+1;return parse(tokens,u,g)}}
    return .error
}
func powparseuntil(_ tokens: [MTMathAtom],_ j:inout Int,_ m:Int,_ delim:String,_ encl:(MathStruct)->MathStruct) -> MathStruct {
    if subsc(tokens[j]) != nil || supsc(tokens[j]) != nil {return .error}
    let g = encl(parseuntil(tokens,&j,m,delim))
    if subsc(tokens[j-1]) != nil {return .error}
    let gh = supsc(tokens[j-1])
    switch (g,gh) {
        case (.scalar(let ju),.none):return .scalar(ju)
        case (.scalar(let ju),.some(.scalar(let ja))):return .scalar(pow(ju,ja))
        default: return .error
    }
}
func powparseuntilS(_ tokens: [MTMathAtom],_ j:inout Int,_ m:Int,_ delim:String,_ encl:(Scalar)->Scalar) -> MathStruct {
    if subsc(tokens[j]) != nil || supsc(tokens[j]) != nil {return .error}
    let g = parseuntil(tokens,&j,m,delim)
    if subsc(tokens[j-1]) != nil {return .error}
    let gh = supsc(tokens[j-1])
    switch (g,gh) {
        case (.scalar(let ju),.none):return .scalar(encl(ju))
        case (.scalar(let ju),.some(.scalar(let ja))):return .scalar(pow(encl(ju),ja))
        default: return .error
    }
}
func fcall(_ tokens: [MTMathAtom],_ j:inout Int,_ m:Int,_ encl:(MathStruct)->MathStruct) -> MathStruct {
    if subsc(tokens[j]) != nil || supsc(tokens[j]) != nil {return .error};j=j+1
    if tokens[j].nucleus != "(" {return .error}
    return powparseuntil(tokens,&j,m,")",encl)
}
func fcallS(_ tokens: [MTMathAtom],_ j:inout Int,_ m:Int,_ encl:(Scalar)->Scalar) -> MathStruct {
    if subsc(tokens[j]) != nil || supsc(tokens[j]) != nil {return .error};j=j+1
    if tokens[j].nucleus != "(" {return .error}
    return powparseuntilS(tokens,&j,m,")",encl)
}


func fcallSL(_ tokens: [MTMathAtom],_ j:inout Int,_ m:Int,_ encl:([Scalar])->Scalar) -> MathStruct {
    if subsc(tokens[j]) != nil || supsc(tokens[j]) != nil {return .error};j=j+1
    if tokens[j].nucleus != "(" {return .error}
    
//    let gh = parseuntil(tokens,&j,m,",")
//    if subsc(tokens[j-1]) != nil || supsc(tokens[j-1]) != nil {return .error}
    return .error
}


func subsc(_ g:MTMathAtom) -> MathStruct? {
    guard let c = g.subScript else {return nil}
    return parse(c.atoms)
}
func supsc(_ g:MTMathAtom) -> MathStruct? {
    guard let c = g.superScript else {return nil}
    return parse(c.atoms)
}

func parse(_ tokens: [MTMathAtom],_ i:Int = 0,_ mm:Int = -1) -> MathStruct {
    let m = (mm == -1 ? tokens.count:mm)
    var parens=0
    var abs=false
    for test in i..<m {
        print(tokens[test].nucleus)
    }
    print("-=-==-=-")
    for prot in [["+","−"],["·","×"]] {
        for g in i..<m {
            if tokens[g].nucleus=="(" {parens=parens+1}
            if parens==0 {
                if tokens[g].nucleus=="|" || tokens[g].nucleus=="‖" {abs = !abs}
                else if !abs && g != i {
                    for op in prot {
                        if op == tokens[g].nucleus {
                            let l = parse(tokens,i,g)
                            let r = parse(tokens,g+1,m)
                            if subsc(tokens[g]) != nil || supsc(tokens[g]) != nil {return .error}
                            switch (op,l,r) {
                                case ("+",.scalar(let a),.scalar(let b)): return .scalar(a+b)
                                case ("−",.scalar(let a),.scalar(let b)): return .scalar(a+b*Scalar(-1))
                                case ("·",.scalar(let a),.scalar(let b)): return .scalar(a*b)
                                case ("×",.scalar(let a),.scalar(let b)): return .scalar(a*b)
                                case ("+",.vector2(let a),.vector2(let b)): return .vector2(a+b)
                                case ("−",.vector2(let a),.vector2(let b)): return .vector2(a+ScalarProd2(Scalar(-1),b))
                                case ("·",.vector2(let a),.vector2(let b)): return .scalar(DotProd2(a,b))
                                case ("×",.vector2(let a),.vector2(let b)): return .scalar(CrossProd2(a,b))
                                case ("+",.vector3(let a),.vector3(let b)): return .vector3(a+b)
                                case ("−",.vector3(let a),.vector3(let b)): return .vector3(a+ScalarProd3(Scalar(-1),b))
                                case ("·",.vector3(let a),.vector3(let b)): return .scalar(DotProd3(a,b))
                                case ("×",.vector3(let a),.vector3(let b)): return .vector3(CrossProd3(a,b))
                                case ("·",.vector2(let a),.scalar(let b)): return .vector2(ScalarProd2(b,a))
                                case ("×",.vector2(let a),.scalar(let b)): return .vector2(ScalarProd2(b,a))
                                case ("·",.scalar(let a),.vector2(let b)): return .vector2(ScalarProd2(a,b))
                                case ("×",.scalar(let a),.vector2(let b)): return .vector2(ScalarProd2(a,b))
                                case ("·",.vector3(let a),.scalar(let b)): return .vector3(ScalarProd3(b,a))
                                case ("×",.vector3(let a),.scalar(let b)): return .vector3(ScalarProd3(b,a))
                                case ("·",.scalar(let a),.vector3(let b)): return .vector3(ScalarProd3(a,b))
                                case ("×",.scalar(let a),.vector3(let b)): return .vector3(ScalarProd3(a,b))
                                default: return .error
                            }
                        }
                    }
                }
            }
            if tokens[g].nucleus==")" {parens=parens-1}
        }
    }
    var conseq:[MathStruct] = []
    var j=i
    while j<m {
        if let gno = tokens[j] as? MTRadical {
            let qr = gno.radicand==nil ?nil:parse(gno.radicand!.atoms)
            let qd = gno.degree==nil ?nil:parse(gno.degree!.atoms)
            switch (qr,qd) {
                case (.some(.scalar(let qa)),.some(.scalar(let qb))): conseq.append(.scalar(pow(qa,pow(qb,-1))))
                case (.some(.scalar(let qa)),.none):                  conseq.append(.scalar(pow(qa,exactdivide(1,2))))
                default:conseq.append(.error)
            }
            j=j+1
        } else if let gno = tokens[j] as? MTFraction {
            switch (parse(gno.numerator.atoms),parse(gno.denominator.atoms)) {
                case (.scalar(let qa),.scalar(let qb)): conseq.append(.scalar(qa*pow(qb,-1)))
                default:conseq.append(.error)
            }
//            print(conseq.last.latex())
            print("gohak")
            j=j+1
        } else if ("0"..."9").contains(tokens[j].nucleus) || tokens[j].nucleus=="." {
            var pred = ""
            var post = 0
            var hd = false
            var volexp:Scalar? = nil
            while j<m {
                if ("0"..."9").contains(tokens[j].nucleus) {
                    pred = pred+tokens[j].nucleus
                    if hd {post=post+1}
                } else if tokens[j].nucleus=="." {
                    if hd {return .error}
                    hd = true
                } else {break}
                if subsc(tokens[j]) != nil {return .error}
                if let exp = supsc(tokens[j]) {
                    switch exp {
                        case .scalar(let ju): volexp = ju
                        default: return .error
                    }
                    j=j+1
                    break;
                }
                j=j+1
            }
            if pred == "" {return .error}
            if volexp==nil {conseq.append(.scalar(exactdivide(Int(pred)!,pow(10,post))))}
            else {conseq.append(.scalar(pow(exactdivide(Int(pred)!,pow(10,post)),volexp!)))}
        } else if tokens[j].nucleus=="−" {conseq.append(.scalar(Scalar(-1)))
        } else if tokens[j].nucleus=="d" {return .error
        } else if tokens[j].nucleus=="f" {
            if let nun = tokens[j].subScript, let num = Int(nun.stringValue) {
                conseq.append(fcallSL(tokens,&j,m){g in Scalar(num)})
            } else {return .error}
        } else if ("a"..."z").contains(tokens[j].nucleus) || ("A"..."Z").contains(tokens[j].nucleus) || "αΔσμλρωΦνβφθπ".contains(tokens[j].nucleus) {
            if subsc(tokens[j]) != nil {return .error}
            switch (supsc(tokens[j])) {
                case .some(.scalar(let ju)): conseq.append(.scalar(pow(SpecialRef(tokens[j].nucleus),ju)))
                case .none: conseq.append(.scalar(SpecialRef(tokens[j].nucleus)))
                default: return .error
            }
            j=j+1
        } else {
            switch tokens[j].nucleus {
                case "(":
                if subsc(tokens[j]) != nil || supsc(tokens[j]) != nil {return .error}
                conseq.append(powparseuntilS(tokens,&j,m,")"){g in g})
                case "[":
                if tokens[j+1].nucleus != "]" {return .error}
                conseq.append(.error)
                j=j+2
                case "∫":
                if let a=subsc(tokens[j]), let b=supsc(tokens[j]) {
                    let gh = parseuntil(tokens,&j,m,"d")//problem is this parseuntil- it does a superscipt/subscript check.
                    if case .error = gh {return .error}
                    if subsc(tokens[j-1]) != nil || supsc(tokens[j-1]) != nil {return .error}
                    if subsc(tokens[j]) != nil || supsc(tokens[j]) != nil {return .error}
                    let f = tokens[j].nucleus
                    j=j+1
                    switch (gh,a,b) {
                        case (.scalar(let g), .scalar(let a),.scalar(let b)): conseq.append(.scalar(Integral(g,a,b,f)))
                        case (.vector2(let g),.scalar(let a),.scalar(let b)): conseq.append(.vector2(Integral2(g,a,b,f)))
                        case (.vector3(let g),.scalar(let a),.scalar(let b)): conseq.append(.vector3(Integral3(g,a,b,f)))
                        default: return .error
                    }
                } else {return .error}
                case "‖":
                if subsc(tokens[j]) != nil || supsc(tokens[j]) != nil {return .error}
                conseq.append(powparseuntil(tokens,&j,m,"‖"){gh in switch gh {
                    case .vector2(let a): return .scalar(Magnitude2(a))
                    case .vector3(let a): return .scalar(Magnitude3(a))
                    default: return .error
                }})
                case "|":
                if subsc(tokens[j]) != nil || supsc(tokens[j]) != nil {return .error}
                conseq.append(powparseuntilS(tokens,&j,m,"|"){g in Abs(g)})
                
                
                case "min": conseq.append(fcallSL(tokens,&j,m){g in MinScalar(g)})
                case "max": conseq.append(fcallSL(tokens,&j,m){g in MaxScalar(g)})
                
                case "sin": conseq.append(fcallS(tokens,&j,m){g in SinScalar(g)})
                case "cos": conseq.append(fcallS(tokens,&j,m){g in CosScalar(g)})
                case "sec": conseq.append(fcallS(tokens,&j,m){g in pow(CosScalar(g),-1)})
                case "csc": conseq.append(fcallS(tokens,&j,m){g in pow(SinScalar(g),-1)})
                case "tan": conseq.append(fcallS(tokens,&j,m){g in SinScalar(g)*pow(CosScalar(g),-1)})
                case "cot": conseq.append(fcallS(tokens,&j,m){g in CosScalar(g)*pow(SinScalar(g),-1)})
                
                case "arcsin": conseq.append(fcall(tokens,&j,m){g in .error})
                case "arccos": conseq.append(fcall(tokens,&j,m){g in .error})
                case "arctan": conseq.append(fcall(tokens,&j,m){g in .error})
                
                case "sinh": conseq.append(fcall(tokens,&j,m){g in .error})
                case "cosh": conseq.append(fcall(tokens,&j,m){g in .error})
                case "tanh": conseq.append(fcall(tokens,&j,m){g in .error})

                case "ln": conseq.append(fcallS(tokens,&j,m){g in LnScalar(g)})
                
                
                case "log":
                if let a=subsc(tokens[j]),supsc(tokens[j]) == nil {
                    switch a {
                        case .scalar(let aa):
                        if tokens[j+1].nucleus != "(" {return .error}; j=j+1
                        conseq.append(powparseuntilS(tokens,&j,m,")"){g in LnScalar(g)*pow(LnScalar(aa),-1)})
                        default: return .error
                    }
                } else {return .error}
                default:
                print("unrecognized character:",tokens[j].nucleus)
                return .error
            }
        }
    }
//    print(conseq.count)
    
    if conseq.count==0 {return .error}
//    switch conseq[0] {
//        case .scalar(let a): print("sc ",a.latex())
//        case .vector2(let a): print("v2 ",a.latex())
//        case .vector3(let a): print("v3 ",a.latex())
//        default: print("ERROR")
//    }
    return conseq[1...].reduce(conseq[0]){a,b in a*b}
}

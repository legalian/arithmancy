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
func assemble(_ l:MathStruct,_ r:MathStruct,_ op:String) -> MathStruct {
    switch (op,l,r) {
        case ("+",.scalar(let a),.scalar(let b)): return .scalar(a+b)
        case ("-",.scalar(let a),.scalar(let b)): return .scalar(a+b*Scalar(-1))
        case ("*",.scalar(let a),.scalar(let b)): return .scalar(a*b)
        default: return .error
    }
}




func parseuntil(_ tokens: [MTMathAtom],_ j:inout Int,_ m:Int,_ delim:String) -> MathStruct {
    for g in j..<m {
        if delim == tokens[g].nucleus {j=g+1;return parse(tokens,j-1,g)}
    }
    return .error
}

func powparseuntil(_ tokens: [MTMathAtom],_ j:inout Int,_ m:Int,_ delim:String) -> MathStruct {
    for g in j..<m {
        if delim == tokens[g].nucleus {j=g+1;return parse(tokens,j-1,g)}
    }
    return .error
}



func parse(_ tokens: [MTMathAtom],_ i:Int = 0,_ mm:Int = -1) -> MathStruct {
    let m = (mm == -1 ? tokens.count:mm)
    var parens=0
    var abs=false
    for test in tokens {
        print(test.nucleus)
    }
    print("-=-==-=-")
    for prot in [["+","-"],["*"]] {
        for g in i..<m {
            if tokens[g].nucleus=="(" {parens=parens+1}
            if parens==0 {
                if tokens[g].nucleus=="|" {abs = !abs}
                else if !abs {
                    for op in prot {if op == tokens[g].nucleus {return assemble(parse(tokens,i,g),parse(tokens,g+1,m),op)}}
                }
            }
            if tokens[g].nucleus==")" {parens=parens-1}
        }
    }
    var conseq:[MathStruct] = []
    var j=i
    while j<m {
        if let ifn = Int(tokens[j].nucleus) {
            conseq.append(.scalar(Scalar(ifn)))
        } else {
            switch tokens[j].nucleus {
                case "(": conseq.append(parseuntil(tokens,&j,m,")"))
                case "[":
                if tokens[j+1].nucleus != "]" {return .error}
                conseq.append(.error)
                j=j+2
                case "∫":
                conseq.append(.error)//integral parseuntil(tokens,&j,m,")")), then variable
                j=j+1
                case "|":
                let gh = parseuntil(tokens,&j,m,"|")
                switch gh {
                    case .scalar(let a): conseq.append(.scalar(Abs(a)))
                    default: return .error
                }
                case "‖":
                let gh = parseuntil(tokens,&j,m,"‖")
                switch gh {
                    case .vector2(let a): conseq.append(.scalar(Magnitude2(a)))
                    case .vector3(let a): conseq.append(.scalar(Magnitude3(a)))
                    default: return .error
                }
                case "sin":
                if tokens[j+1].nucleus != "(" {return .error}; j=j+1
                conseq.append(.error)//sin parseuntil(tokens,&j,m,")"))
                case "cos":
                if tokens[j+1].nucleus != "(" {return .error}; j=j+1
                conseq.append(.error)//sin parseuntil(tokens,&j,m,")"))
                case "tan":
                if tokens[j+1].nucleus != "(" {return .error}; j=j+1
                conseq.append(.error)//sin parseuntil(tokens,&j,m,")"))
                case "csc":
                if tokens[j+1].nucleus != "(" {return .error}; j=j+1
                conseq.append(.error)//sin parseuntil(tokens,&j,m,")"))
                case "sec":
                if tokens[j+1].nucleus != "(" {return .error}; j=j+1
                conseq.append(.error)//sin parseuntil(tokens,&j,m,")"))
                case "cot":
                if tokens[j+1].nucleus != "(" {return .error}; j=j+1
                conseq.append(.error)//sin parseuntil(tokens,&j,m,")"))
                
                case "arcsin":
                if tokens[j+1].nucleus != "(" {return .error}; j=j+1
                conseq.append(.error)//sin parseuntil(tokens,&j,m,")"))
                case "arccos":
                if tokens[j+1].nucleus != "(" {return .error}; j=j+1
                conseq.append(.error)//sin parseuntil(tokens,&j,m,")"))
                case "arctan":
                if tokens[j+1].nucleus != "(" {return .error}; j=j+1
                conseq.append(.error)//sin parseuntil(tokens,&j,m,")"))
                
                case "sinh":
                if tokens[j+1].nucleus != "(" {return .error}; j=j+1
                conseq.append(.error)//sin parseuntil(tokens,&j,m,")"))
                case "cosh":
                if tokens[j+1].nucleus != "(" {return .error}; j=j+1
                conseq.append(.error)//sin parseuntil(tokens,&j,m,")"))
                case "tanh":
                if tokens[j+1].nucleus != "(" {return .error}; j=j+1
                conseq.append(.error)//sin parseuntil(tokens,&j,m,")"))
                
                case "ln":
                if tokens[j+1].nucleus != "(" {return .error}; j=j+1
                conseq.append(.error)//sin parseuntil(tokens,&j,m,")"))
                
                
                default: return .error
            }
        }
    }
    return .error
}

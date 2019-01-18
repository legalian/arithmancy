//
//  Algebra.swift
//  Calcuplot
//
//  Created by Parker on 1/11/19.
//  Copyright © 2019 Parker. All rights reserved.
//

import Foundation




infix operator %%
func %%<T: BinaryInteger>(lhs: T, rhs: T) -> T {
    let rem = lhs % rhs // -rhs <= rem <= rhs
    return rem >= 0 ? rem : rem + rhs
}
func gcf(_ a:Int,_ b:Int) -> Int {
    if a==0 || b==0 {return 1}
    let r = abs(a) % abs(b)
    if r != 0 {return gcf(abs(b), r)}
    else {return abs(b)}
}
func gcf(_ a:[Int]) -> Int {return a.reduce(0,gcf)}
func pow(_ a:Int,_ b:Int) -> Int {return Int(pow(Double(a),Double(b)))}

func any<T>(_ a:[T],_ c:(T)->Bool) -> Bool {
    for b in a {if c(b) {return true}}
    return false
}
func all<T>(_ a:[T],_ c:(T)->Bool) -> Bool {
    for b in a {if !c(b) {return false}}
    return true
}
func setEq<T>(_ a:[T],_ b:[T],_ c:(T,T)->Bool) -> Bool {
    if a.count != b.count {return false}
    var d = [Bool](repeating:true,count:a.count)
    for x in a {
        var h=false
        for y in 0..<b.count {if c(x,b[y]) && d[y] {h=true;d[y]=false;break}}
        if !h {return false}
    }
    return true
}
func doubleRemap<T>(_ a:[T],_ b:(T,T)->(T?,T?,T?))->[T]{
    var a=a
    var c=0
    while c<a.count-1 {
        var d=c+1
        while d<a.count {
            let g=b(a[c],a[d])
            if let gg=g.2 {a.append(gg)}
            if let gg=g.1 {a[d]=gg;d=d+1}
            else {a.remove(at:d)}
            if let gg=g.0 {a[c]=gg}
            else {a.remove(at:c);d=c+1}
        }
        c=c+1
    }
    return a
}


func rationalcoefsplit(_ a:Scalar) -> (Scalar,Int,Int) {
    if case .mult(let g) = a {
        var ci = -1
        var c = 1
        var fi = -1
        var f = 1
        for n in 0..<g.count {
            if case .constant(let cl) = g[n] {c=cl;ci=n}
            if case .power(.constant(let cl),.constant(-1)) = g[n] {f=cl;fi=n}
        }
        var h = g;
        if ci != -1 {h.remove(at:ci);}
        if fi != -1 {h.remove(at:fi);}
        return (.mult(h),c,f)
    }
    if case .constant(let c) = a {return (.constant(1),c,1)}
    return (a,1,1)
}



func asrational(_ a:Scalar) -> (Int,Int)? {
    switch a {
        case .constant(let c): return (c,1)
        case .power(.constant(let bi),.constant(-1)):
            if bi<0 {return (-1,-bi)}
            return (1,bi)
        case .mult(let a):
            if a.count==2 {
                switch (a[0],a[1]) {
                    case (.constant(let x),.power(.constant(let bi),.constant(-1))):
                    if bi<0 {return (-x,-bi)}
                    return (x,bi)
                    case (.power(.constant(let bi),.constant(-1)),.constant(let x)):
                    if bi<0 {return (-x,-bi)}
                    return (x,bi)
                    default:return nil
                }
            } else {return nil}
        default:return nil
    }
}
func aspower(_ a:Scalar) -> (Scalar,Scalar) {
    if case .power(let b,let e) = a {return (b,e)}
    return (a,.constant(1))
}
func coefsplit(_ a:Scalar) -> (Scalar,Int) {
    if case .mult(let g) = a {
        for n in 0..<g.count {
            if case .constant(let c) = g[n] {
                var h = g;h.remove(at:n);
                return (.mult(h),c)
            }
        }
    }
    if case .constant(let c) = a {return (.constant(1),c)}
    return (a,1)
}
func asint(_ a:Scalar) -> Int? {
    if case .constant(let c) = a {return c}
    return nil
}
func asmultchain(_ a:Scalar) -> [Scalar] {
    if case .mult(let b) = a {return b}
    if case .constant(let c) = a, c == 1 {return []}
    return [a]
}
func asaddchain(_ a:Scalar) -> [Scalar] {
    if case .add(let b) = a {return b}
    if case .constant(let c) = a, c == 0 {return []}
    return [a]
}

func mingcf(_ a:Scalar) -> Scalar {
    var g:[Scalar]=[]
    for a in asmultchain(a) {
        if let (aen,_) = asrational(aspower(a).1), aen < -1 {g.append(a)}
    }
    return .mult(g)
}

func gcf(_ a:Scalar,_ b:Scalar) -> Scalar {//rethink this... entire premise based on the fact that no two bases will be equivalent within a shallow-simplified multchain. That's not true... (e)
    var cu:[Scalar] = []
    for a in asmultchain(a) {
        let (ab,ae) = aspower(a)
        for b in asmultchain(b) {
            let (bb,be) = aspower(b)
            let (bewc,bec) = coefsplit(be)
            let (aewc,aec) = coefsplit(ae)
            guard bewc==aewc else {continue}
            if let ab = asint(ab), let bb = asint(bb) {cu.append(.power(.constant(gcf(ab,bb)),aec<bec ? ae:be))}
            else if ab==bb {cu.append(aec<bec ? a:b)}
        }
    }
    for c in [a,b] {
        for a in asmultchain(c) {
            let (ab,ae) = aspower(a)
            let (_,aec) = coefsplit(ae)
            if aec<0 {
                if !any(cu,{k in ab==aspower(k).0}) {cu.append(a)}
            }
        }
    }
//    throw//shallow simplify, right?
    return .mult(cu.map{g in g
//        let (b,e) = aspower(g)
//        if let (en,ed) = asrational(e),let b=b as? AddScalar, en<0 {
//            print("denominator should be rationalized here.")
//            return PowScalar(b,exactdivide(en,ed),g.c)
//        }
//        return b
    })
}
func gcf(_ a:[Scalar]) -> Scalar {return a[1...].reduce(a[0],gcf)}



//func absgcf(_ a:Scalar,_ gc:Scalar) -> Scalar {
//    var cu:[Scalar] = []
//    for a in asmultchain(a) {
//        for b in asmultchain(gc) {
//            let (ab,ae) = aspower(a),(bb,be) = aspower(b)
//            if let (aen,aed) = asrational(ae), let (ben,bed) = asrational(be), aed==bed {
//                if let ab = asint(ab), let bb = asint(bb) {cu.append(pow(Scalar(gcf(ab,bb)),exactdivide(aen-ben,bed)))}
//                else if (ab==bb) {cu.append(pow(ab,exactdivide(min(aen,ben),bed)))}
//            }
//        }
//    }
//    for a in asmultchain(a) {
//        let (ab,_) = aspower(a)
//        if !any(cu,{k in ab==aspower(k).0}) {cu.append(a.deepcopy())}
//    }
//    for a in asmultchain(gc) {
//        let (ab,_) = aspower(a)
//        if !any(cu,{k in ab==aspower(k).0}) {cu.append(pow(a,-1))}
//    }
//    return MultScalar(cu,a.c/gc.c).simplifyShallow()
//}
func == (a:Scalar,b:Scalar) -> Bool {
    switch (a,b) {
        case (.constant(let x),.constant(let y)): return x==y
        case (.special(let x),.special(let y)): return x==y
        case (.power(let ax,let ay),.power(let bx,let by)): return ax==bx && ay==by
        case (.add(let x),.add(let y)): return setEq(x,y,==)
        case (.mult(let x),.mult(let y)): return setEq(x,y,==)
        case (.min(let x),.min(let y)): return setEq(x,y,==)
        case (.max(let x),.max(let y)): return setEq(x,y,==)
        case (.ln(let x),.ln(let y)): return x==y
        case (.sin(let x),.sin(let y)): return x==y
        case (.cos(let x),.cos(let y)): return x==y
        case (.abs(let x),.abs(let y)): return x==y
        case (.abs2(let x),.abs2(let y)): return x==y
        case (.abs3(let x),.abs3(let y)): return x==y
        case (.dot2(let ax,let ay),.dot2(let bx,let by)): return ax==bx && ay==by
        case (.dot3(let ax,let ay),.dot3(let bx,let by)): return ax==bx && ay==by
        case (.cross2(let ax,let ay),.cross2(let bx,let by)): return ax==bx && ay==by
        case (.derivative(let ad,let aa,let ash),.derivative(let bd,let ba,let bsh)): return ad==bd && aa==ba && ash==bsh
        case (.integral(let ad,let al,let au,let ash),.integral(let bd,let bl,let bu,let bsh)): return ad==bd && al==bl && au==bu && ash==bsh
        default: return false;
    }
}

func == (a:Vector2,b:Vector2) -> Bool {
    switch (a,b) {
        case (.assemble(let ax,let ay),.assemble(let bx,let by)): return ax==bx && ay==by
        case (.add(let x),.add(let y)): return setEq(x,y,==)
        case (.mult(let ax,let ay),.mult(let bx,let by)): return ax==bx && ay==by
        case (.derivative(let ad,let aa,let ash),.derivative(let bd,let ba,let bsh)): return ad==bd && aa==ba && ash==bsh
        case (.integral(let ad,let al,let au,let ash),.integral(let bd,let bl,let bu,let bsh)): return ad==bd && al==bl && au==bu && ash==bsh
        default: return false
    }
}
func == (a:Vector3,b:Vector3) -> Bool {
    switch (a,b) {
        case (.assemble(let ax,let ay,let az),.assemble(let bx,let by,let bz)): return ax==bx && ay==by && az==bz
        case (.add(let x),.add(let y)): return setEq(x,y,==)
        case (.mult(let ax,let ay),.mult(let bx,let by)): return ax==bx && ay==by
        case (.cross3(let ax,let ay),.cross3(let bx,let by)): return ax==bx && ay==by
        case (.derivative(let ad,let aa,let ash),.derivative(let bd,let ba,let bsh)): return ad==bd && aa==ba && ash==bsh
        case (.integral(let ad,let al,let au,let ash),.integral(let bd,let bl,let bu,let bsh)): return ad==bd && al==bl && au==bu && ash==bsh
        default: return false
    }
}


prefix func -(a:Scalar) -> Scalar {return a * -1}

func +(a:Scalar,b:Scalar) -> Scalar {return .add([a,b])}
func -(a:Scalar,b:Scalar) -> Scalar {return .add([a,-b])}
func +(a:Scalar,b:Int) -> Scalar {return .add([a,.constant(b)])}
func -(a:Scalar,b:Int) -> Scalar {return .add([a,.constant(-b)])}
func +(a:Int,b:Scalar) -> Scalar {return .add([.constant(a),b])}
func -(a:Int,b:Scalar) -> Scalar {return .add([.constant(a),-b])}

func *(a:Scalar,b:Scalar) -> Scalar {return .mult([a,b])}
func /(a:Scalar,b:Scalar) -> Scalar {return .mult([a,reciprocal(b)])}
func *(a:Scalar,b:Int) -> Scalar {return .mult([a,.constant(b)])}
func /(a:Scalar,b:Int) -> Scalar {return .mult([a,reciprocal(b)])}
func *(a:Int,b:Scalar) -> Scalar {return .mult([.constant(a),b])}
func /(a:Int,b:Scalar) -> Scalar {return .mult([.constant(a),reciprocal(b)])}

func exactdivide(_ a:Int,_ b:Int) -> Scalar {
    if b==1 {return .constant(a)}
    if a==1 {return .power(.constant(b),.constant(-1))}
    return .mult([.constant(a),.power(.constant(b),.constant(-1))])
}
func pow(_ b:Scalar,_ e:Scalar) -> Scalar {return .power(b,e)}
func pow(_ b:Scalar,_ e:Int) -> Scalar {return .power(b,.constant(e))}
func pow(_ b:Int,_ e:Scalar) -> Scalar {return .power(.constant(b),e)}
func reciprocal(_ a: Scalar) -> Scalar {return pow(a,-1)}
func reciprocal(_ a: Int) -> Scalar {return exactdivide(1,a)}
func root(_ a: Scalar,_ e:Scalar) -> Scalar {return pow(a,reciprocal(e))}
func root(_ a: Scalar,_ e:Int) -> Scalar {return pow(a,reciprocal(e))}
func root(_ a: Int,_ e:Int) -> Scalar {return pow(.constant(a),reciprocal(e))}




prefix func -(a:Vector2) -> Vector2 {return a * -1}
prefix func -(a:Vector3) -> Vector3 {return a * -1}
func +(_ a:Vector2,_ b:Vector2) -> Vector2{return .add([a,b])}
func +(_ a:Vector3,_ b:Vector3) -> Vector3{return .add([a,b])}
func -(_ a:Vector2,_ b:Vector2) -> Vector2{return .add([a,-b])}
func -(_ a:Vector3,_ b:Vector3) -> Vector3{return .add([a,-b])}
func *(_ a:Vector2,_ b:Scalar) -> Vector2{return .mult(b,a)}
func *(_ a:Vector3,_ b:Scalar) -> Vector3{return .mult(b,a)}
func *(_ b:Scalar,_ a:Vector2) -> Vector2{return .mult(b,a)}
func *(_ b:Scalar,_ a:Vector3) -> Vector3{return .mult(b,a)}
func *(_ a:Vector2,_ b:Int) -> Vector2{return .mult(.constant(b),a)}
func *(_ a:Vector3,_ b:Int) -> Vector3{return .mult(.constant(b),a)}
func *(_ b:Int,_ a:Vector2) -> Vector2{return .mult(.constant(b),a)}
func *(_ b:Int,_ a:Vector3) -> Vector3{return .mult(.constant(b),a)}
func /(_ a:Vector2,_ b:Scalar) -> Vector2{return a*reciprocal(b)}
func /(_ a:Vector3,_ b:Scalar) -> Vector3{return a*reciprocal(b)}
func /(_ a:Vector2,_ b:Int) -> Vector2{return a*reciprocal(b)}
func /(_ a:Vector3,_ b:Int) -> Vector3{return a*reciprocal(b)}



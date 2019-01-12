//
//  Algebra.swift
//  Calcuplot
//
//  Created by Parker on 1/11/19.
//  Copyright © 2019 Parker. All rights reserved.
//

import Foundation


struct Vec3 {
    var x:Double
    var y:Double
    var z:Double
    init(_ a:Double,_ b:Double,_ c:Double) {x=a;y=b;z=c}
}
struct Vec2 {
    var x:Double
    var y:Double
    init(_ a:Double,_ b:Double) {x=a;y=b}
}

func +(_ x:Vec2,_ y:Vec2) -> Vec2 {return Vec2(x.x+y.x,x.y+y.y)}
func +(_ x:Vec3,_ y:Vec3) -> Vec3 {return Vec3(x.x+y.x,x.y+y.y,x.z+y.z)}
func *(_ x:Vec2,_ y:Double) -> Vec2 {return Vec2(x.x+y,x.y+y)}
func *(_ x:Vec3,_ y:Double) -> Vec3 {return Vec3(x.x+y,x.y+y,x.z*y)}

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


func asrational(_ a:Scalar) -> (Int,Int)? {
    if let a=asint(a) {return (a,1)}
    if let a=a as? PowScalar, type(of:a.e) == Scalar.self, a.e.c == -1 {
        if a.b.c<0 {return (-a.c,-a.b.c)}
        return (a.c,a.b.c)
    }
    return nil
}
func exactdivide(_ a:Int,_ b:Int) -> Scalar {
    if b==1 {return Constant(a)}
    return pow(Constant(b),Constant(-1),a)
}
func aspower(_ a:Scalar) -> (Scalar,Scalar) {
    if let a=a as? PowScalar {return (a.b,a.e)}
    return (a,Constant(1))
}
func asint(_ a:Scalar) -> Int? {
    if a is Constant {return a.c}
    return nil
}
func asmultchain(_ a:Scalar) -> [Scalar] {
    if let a=a as? MultScalar {return a.a}
    if a is Constant {return []}
    return [a/a.c]
}
func asaddchain(_ a:Scalar) -> [Scalar] {
    if let a=a as? AddScalar {
        if a.c != 1 {return a.a.map{g in return g*Constant(a.c)}}
        else {return a.a}
    }
    if let a=asint(a),a==0 {return []}
    return [a]
}

func mingcf(_ a:Scalar) -> Scalar {
    var g:[Scalar]=[]
    for a in asmultchain(a) {
        if let (aen,_) = asrational(aspower(a).1), aen < -1 {g.append(a.deepcopy())}
    }
    return MultScalar(g)
}

func gcf(_ a:Scalar,_ b:Scalar) -> Scalar {//rethink this... entire premise based on the fact that no two bases will be equivalent within a shallow-simplified multchain. That's not true... (e)
    var cu:[Scalar] = []
    for a in asmultchain(a) {
        let (ab,ae) = aspower(a)
        for b in asmultchain(b) {
            let (bb,be) = aspower(b)
            guard coefEqual(ae,be) else {continue}
            if ae.c<be.c {
                if let ab = asint(ab), let bb = asint(bb) {
                    cu.append(pow(Constant(gcf(ab,bb)),ae.deepcopy()))
                } else if ab==bb {cu.append(a.deepcopy())}
            } else {
                if let ab = asint(ab), let bb = asint(bb) {
                    cu.append(pow(Constant(gcf(ab,bb)),be.deepcopy()))
                } else if ab==bb {cu.append(b.deepcopy())}
            }
        }
    }
    for c in [a,b] {
        for a in asmultchain(c) {
            let (ab,ae) = aspower(a)
            if ae.c<0 {
                if !any(cu,{k in ab==aspower(k).0}) {cu.append(a.deepcopy())}
            }
        }
    }
    return MultScalar(cu.map{g in g
//        let (b,e) = aspower(g)
//        if let (en,ed) = asrational(e),let b=b as? AddScalar, en<0 {
//            print("denominator should be rationalized here.")
//            return PowScalar(b,exactdivide(en,ed),g.c)
//        }
//        return b
    },gcf(a.c,b.c)).simplifyShallow()
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


func coefEqual(_ a:Scalar,_ b:Scalar) -> Bool {
    if a is Constant && b is Constant {return true}
    else if let ac=a as? AddScalar, let bc=b as? AddScalar {return setEq(ac.a,bc.a,==)}
    else if let ac=a as? MultScalar, let bc=b as? MultScalar {return setEq(ac.a,bc.a,==)}
    else if let ac=a as? PowScalar, let bc=b as? PowScalar {return ac.b==bc.b && ac.e==bc.e}
    else if let ac=a as? SpecialRef, let bc=b as? SpecialRef {return ac.va==bc.va}
    else if let ac=a as? LnScalar, let bc=b as? LnScalar {return ac.b==bc.b}
    else if let ac=a as? SinScalar, let bc=b as? SinScalar {return ac.b==bc.b}
    else if let ac=a as? CosScalar, let bc=b as? CosScalar {return ac.b==bc.b}
    else if let ac=a as? MinScalar, let bc=b as? MinScalar {return setEq(ac.a,bc.a,==)}
    else if let ac=a as? MaxScalar, let bc=b as? MaxScalar {return setEq(ac.a,bc.a,==)}
    else if let ac=a as? Abs, let bc=b as? Abs {return ac.a==bc.a}
    else if let ac=a as? Integral, let bc=b as? Integral {return ac.d==bc.d && ac.l==bc.l && ac.u==bc.u && ac.va==bc.va}
    else if let ac=a as? Derivative, let bc=b as? Derivative {return ac.d==bc.d && ac.t==bc.t && ac.va==bc.va}
    else if let ac=a as? Magnitude2, let bc=b as? Magnitude2 {return ac.a==bc.a}
    else if let ac=a as? Magnitude3, let bc=b as? Magnitude3 {return ac.a==bc.a}
    else if let ac=a as? CrossProd2, let bc=b as? CrossProd2 {return ac.a==bc.a && ac.b==bc.b}
    else if let ac=a as? DotProd2, let bc=b as? DotProd2 {return ac.a==bc.a && ac.b==bc.b}
    else if let ac=a as? DotProd3, let bc=b as? DotProd3 {return ac.a==bc.a && ac.b==bc.b}
    else {
        if type(of:b) === type(of:a) {
            print("this could be an unimplemented case.")
        }
        return false
    }
}
func == (a:Scalar,b:Scalar) -> Bool {if a.c != b.c {return false};return coefEqual(a,b)}
func +(a:Scalar,b:Scalar) -> Scalar {return AddScalar([a.deepcopy(),b.deepcopy()]).simplifyShallow()}
func -(a:Scalar,b:Scalar) -> Scalar {return AddScalar([a.deepcopy(),b * -1]).simplifyShallow()}

func *(a:Scalar,b:Scalar) -> Scalar {return MultScalar([a.deepcopy(),b.deepcopy()]).simplifyShallow()}
func *(a:Scalar,b:Int) -> Scalar {var temp = a.deepcopy();temp.c*=b;return temp}
func /(a:Scalar,b:Scalar) -> Scalar {return a * pow(b,-1)}
func /(a:Scalar,b:Int) -> Scalar {return a/Constant(b)}
func pow(_ a:Scalar,_ b:Scalar) -> Scalar {return PowScalar(a.deepcopy(),b.deepcopy()).simplifyShallow()}
func pow(_ a:Scalar,_ b:Scalar,_ c:Int) -> Scalar {return PowScalar(a.deepcopy(),b.deepcopy(),c).simplifyShallow()}
func pow(_ a:Scalar,_ c:Int) -> Scalar {return PowScalar(a.deepcopy(),Constant(c)).simplifyShallow()}

func +(_ a:Vector2,_ b:Vector2) -> Vector2{return AddVector2([a,b])}
func +(_ a:Vector3,_ b:Vector3) -> Vector3 {return AddVector3([a,b])}
func -(_ a:Vector2,_ b:Vector2) -> Vector2{return AddVector2([a,ScalarProd2(Constant(-1),b)])}
func -(_ a:Vector3,_ b:Vector3) -> Vector3 {return AddVector3([a,ScalarProd3(Constant(-1),b)])}

func == (_ a:Vector2,_ b:Vector2) -> Bool {
    if      let ac=a as? Assemble2,   let bc=b as? Assemble2   {return ac.x==bc.x && ac.y==bc.y}
    else if let ac=a as? ScalarProd2, let bc=b as? ScalarProd2 {return ac.a==bc.a && ac.b==bc.b}
    else if let ac=a as? AddVector2,  let bc=b as? AddVector2  {return setEq(ac.a,bc.a,==)}
    else if let ac=a as? Integral2,   let bc=b as? Integral2   {return ac.d==bc.d && ac.l==bc.l && ac.u==bc.u && ac.va==bc.va}
    else if let ac=a as? Derivative2, let bc=b as? Derivative2 {return ac.d==bc.d && ac.t==bc.t && ac.va==bc.va}
    else {
        if type(of:b) === type(of:a) {
            print("this could be an unimplemented case.")
        }
        return false
    }
}
func == (_ a:Vector3,_ b:Vector3) -> Bool {
    if      let ac=a as? Assemble3,   let bc=b as? Assemble3   {return ac.x==bc.x && ac.y==bc.y && ac.z==bc.z}
    else if let ac=a as? ScalarProd3, let bc=b as? ScalarProd3 {return ac.a==bc.a && ac.b==bc.b}
    else if let ac=a as? AddVector3,  let bc=b as? AddVector3  {return setEq(ac.a,bc.a,==)}
    else if let ac=a as? Integral3,   let bc=b as? Integral3   {return ac.d==bc.d && ac.l==bc.l && ac.u==bc.u && ac.va==bc.va}
    else if let ac=a as? Derivative3, let bc=b as? Derivative3 {return ac.d==bc.d && ac.t==bc.t && ac.va==bc.va}
    else if let ac=a as? CrossProd3,  let bc=b as? CrossProd3  {return ac.a==bc.a && ac.b==bc.b}
    else {
        if type(of:b) === type(of:a) {
            print("this could be an unimplemented case.")
        }
        return false
    }
}



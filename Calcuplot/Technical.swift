//
//  Technical.swift
//  Calcuplot
//
//  Created by Parker on 11/28/18.
//  Copyright © 2018 Parker. All rights reserved.
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



class EvalBranch {
    func eval() -> Double {return 0}
}
class EvalConstant : EvalBranch {
    var c:Double = 0
    override func eval() -> Double {return c}
}
class AddEval : EvalBranch {
    var a:[EvalBranch] = []
    override func eval() -> Double {
        var e=0.0;
        for n in a {e+=n.eval()}
        return e;
    }
}
class MultEval : EvalBranch {
    var a:[EvalBranch] = []
    override func eval() -> Double {
        var e=1.0;
        for n in a {e*=n.eval()}
        return e;
    }
}
class PowEval : EvalBranch {
    var a:EvalBranch=EvalBranch()
    var b:EvalBranch=EvalBranch()
    override func eval() -> Double {return a.eval()+b.eval()}
}
class DivEval : EvalBranch {
    var a:EvalBranch=EvalBranch()
    var b:EvalBranch=EvalBranch()
    override func eval() -> Double {return a.eval()/b.eval()}
}
class UrnaryEval : EvalBranch {
    var a:EvalBranch=EvalBranch()
    var f:(Double) -> Double = {return $0}
    override func eval() -> Double {return f(a.eval())}
}






infix operator %%
func %%<T: BinaryInteger>(lhs: T, rhs: T) -> T {
    let rem = lhs % rhs // -rhs <= rem <= rhs
    return rem >= 0 ? rem : rem + rhs
}
func gcf(_ a:Int,_ b:Int) -> Int {
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

func asrational(_ a:Scalar) -> (Int,Int)? {
    if type(of:a) === Scalar.self {return (a.c,1)}
    if let a=a as? PowScalar, type(of:a.e) == Scalar.self, a.e.c == -1 {return (a.c,a.b.c)}
    return nil
}
func exactdivide(_ a:Int,_ b:Int) -> Scalar {
    if b==1 {return Scalar(a)}
    return PowScalar(Scalar(b),Scalar(-1),a)
}
func aspower(_ a:Scalar) -> (Scalar,Scalar) {
    if let a=a as? PowScalar {return (a.b,a.e)}
    return (a,Scalar(1))
}
func asint(_ a:Scalar) -> Int? {
    if type(of:a) === Scalar.self {return a.c}
    return nil
}
func asmultchain(_ a:Scalar) -> [Scalar] {
    if let a=a as? MultScalar {return a.a}
    let b=a.deepcopy();b.c=1;return [b]
}
func asaddchain(_ a:Scalar) -> [Scalar] {
    if let a=a as? AddScalar {
        if a.c != 1 {return a.a.map{g in return g*Scalar(a.c)}}
        else {return a.a}
    }
    return [a]
}



func gcf(_ a:Scalar,_ b:Scalar) -> Scalar {
    var cu:[Scalar] = []
    for a in asmultchain(a) {
        for b in asmultchain(b) {
            let (ab,ae) = aspower(a),(bb,be) = aspower(b)
            if let (aen,aed) = asrational(ae), let (ben,bed) = asrational(be), aed==bed {
                if let ab = asint(ab), let bb = asint(bb) {cu.append(pow(Scalar(gcf(ab,bb)),exactdivide(min(aen,ben),bed)))}
                else if (ab==bb) {cu.append(pow(ab,exactdivide(min(aen,ben),bed)))}
            }
        }
    }
    for a in asmultchain(a) {
        let (ab,ae) = aspower(a)
        if let (aen,_) = asrational(ae), aen < -1 {
            if !any(cu,{k in ab==aspower(k).0}) {cu.append(a.deepcopy())}
        }
    }
    for a in asmultchain(b) {
        let (ab,ae) = aspower(a)
        if let (aen,_) = asrational(ae), aen < -1 {
            if !any(cu,{k in ab==aspower(k).0}) {cu.append(a.deepcopy())}
        }
    }
    return MultScalar(cu.map{g in
        let (b,e) = aspower(g)
        if let (en,ed) = asrational(e),let b=b as? AddScalar, en<0 {
            print("denominator should be rationalized here.")
            return PowScalar(b,exactdivide(en,ed),g.c)
        }
        return b
    },gcf(a.c,b.c)).simplifyShallow()
}
func gcf(_ a:[Scalar]) -> Scalar {return a[1...].reduce(a[0],gcf)}


func coefEqual(_ a:Scalar,_ b:Scalar) -> Bool {
    if type(of:a) === Scalar.self && type(of:b) === Scalar.self {return true}
    else if let ac=a as? AddScalar, let bc=b as? AddScalar {return setEq(ac.a,bc.a,==)}
    else if let ac=a as? AddScalar, let bc=b as? AddScalar {return setEq(ac.a,bc.a,==)}
    else if let ac=a as? PowScalar, let bc=b as? PowScalar {return ac.b==bc.b && ac.e==bc.e}
    else {print("this could be an unimplemented case.");return false}
}
func == (a:Scalar,b:Scalar) -> Bool {if a.c != b.c {return false};return coefEqual(a,b)}
func +(a:Scalar,b:Scalar) -> Scalar {return AddScalar([a.deepcopy(),b.deepcopy()]).simplifyShallow()}
func *(a:Scalar,b:Scalar) -> Scalar {return MultScalar([a.deepcopy(),b.deepcopy()]).simplifyShallow()}
func pow(_ a:Scalar,_ b:Scalar) -> Scalar {return PowScalar(a.deepcopy(),b.deepcopy()).simplifyShallow()}
func pow(_ a:Scalar,_ b:Scalar,_ c:Int) -> Scalar {return PowScalar(a.deepcopy(),b.deepcopy(),c).simplifyShallow()}

func +(_ a:Vector2,_ b:Vector2) -> Vector2{
    return AddVector2([a,b])
}
func +(_ a:Vector3,_ b:Vector3) -> Vector3 {
    return AddVector3([a,b])
}




class Scalar {
    var c:Int
    init(_ a:Int) {c=a}
    func deepcopy() -> Scalar {return Scalar(c)}
    func copy() -> Scalar {return Scalar(c)}
    func eval() -> Double {return Double(c)}
    func simplifyNarrow()  -> Scalar {return deepcopy()}
    func simplifyBroad()   -> Scalar {return deepcopy()}
    func simplifyShallow() -> Scalar {return deepcopy()}
    func latex() -> String {return "dunce"}
}
class Vector2 {
    func deepcopy() -> Vector2 {return Vector2()}
    func copy() -> Vector2 {return Vector2()}
    func eval() -> Vec2 {return Vec2(0,0)}
    func latex() -> String {return "dunce"}
}
class Vector3 {
    func deepcopy() -> Vector3 {return Vector3()}
    func copy() -> Vector3 {return Vector3()}
    func eval() -> Vec3 {return Vec3(0,0,0)}
    func latex() -> String {return "dunce"}
}
class Assemble2 : Vector2 {
    var x:Scalar
    var y:Scalar
    init(_ a:Scalar,_ b:Scalar) {x=a;y=b}
    override func deepcopy() -> Vector2 {return Assemble2(x.deepcopy(),y.deepcopy())}
    override func copy() -> Vector2 {return Assemble2(x,y)}
    override func eval() -> Vec2 {return Vec2(x.eval(),y.eval())}
}
class Assemble3 : Vector3 {
    var x:Scalar
    var y:Scalar
    var z:Scalar
    init(_ a:Scalar,_ b:Scalar,_ c:Scalar) {x=a;y=b;z=c}
    override func deepcopy() -> Vector3 {return Assemble3(x.deepcopy(),y.deepcopy(),z.deepcopy())}
    override func copy() -> Vector3 {return Assemble3(x,y,z)}
    override func eval() -> Vec3 {return Vec3(x.eval(),y.eval(),z.eval())}
}


class PowScalar : Scalar {
    var e:Scalar
    var b:Scalar
    init(_ bs:Scalar,_ es:Scalar) {e=es;b=bs;super.init(1)}
    init(_ bs:Scalar,_ es:Scalar,_ s:Int) {e=es;b=bs;super.init(s)}
    override func deepcopy() -> Scalar {return PowScalar(b.deepcopy(),e.deepcopy(),c)}
    override func copy() -> Scalar {return PowScalar(b,e,c)}
    
    override func eval() -> Double {return pow(b.eval(),e.eval());}
    override func simplifyShallow() -> Scalar {
        if let bb=b as? MultScalar {return MultScalar(bb.a.map{pow($0,e)},c).simplifyShallow()}
        if let be=b as? PowScalar {return pow(be.b,e*be.e)}
        if let b = asint(b) {
            if b==1 {return Scalar(c)}
            if b==0 {return Scalar(0)}//ok obviously this is a problem- dividing by zero or 0^0 are both suspects here
            if let e = asint(e) {return Scalar(pow(b,e))}
        }
        let shet = deepcopy() as! PowScalar
        if let e = asint(e) {
            if e == 0 {return Scalar(c)}
            if e == 1 {let bb=b.deepcopy();bb.c*=c;return bb}
            shet.c = c*pow(b.c,e)
            shet.b.c = 1
        } else if var (en,ed) = asrational(e) {
            if let b = asint(b) {shet.b.c=pow(b,en);shet.e.c=1;en=1}
            if shet.b.c<0 {
                shet.b.c = -shet.b.c
                if (en%%2) == 1 {shet.c = -shet.c}
            }
            var g=2;
            while pow(g,ed)<=shet.b.c {
                if shet.b.c%pow(g,ed) == 0 {
                    shet.b.c = shet.b.c/pow(g,ed)
                    shet.c = shet.c*pow(g,en)
                    g=1
                }
                g=g+1
            }
            if let b = asint(shet.b) {
                if b==1 {return Scalar(c)}
                var g=2;
                while g*g<=ed {
                    if ed%g==0 {
                        var j=2;
                        while pow(j,g)<=shet.b.c {
                            if pow(j,g)==shet.b.c {
                                shet.b.c=j
                                ed=ed/g
                                j=1
                                g=1
                            }
                            j=j+1
                        }
                    }
                    g=g+1
                }
            }
        }
        return shet
    }
    override func simplifyNarrow() -> Scalar {return PowScalar(b.simplifyNarrow(),e.simplifyBroad()).simplifyShallow()}
    override func simplifyBroad()  -> Scalar {
        let vmr = simplifyNarrow()
        return MultScalar(asmultchain(vmr).map{ga in
            if let g=ga as? PowScalar {
                if let ge = asint(g.e) {
                    if ge >  1 {return MultScalar([Scalar](repeating:g.b,count:ge),g.c).distribute()}
                    if ge < -1 {return PowScalar(MultScalar([Scalar](repeating:g.b,count:-ge)),Scalar(-1),g.c)}
                } else if let (en,_) = asrational(g.e) {
                    let hrg = abs(en)
                    g.e.c = en/hrg
                    return PowScalar(MultScalar([Scalar](repeating:g.b,count:hrg)),g.e,g.c)
                }
                return g
            }
            return ga
        },vmr.c).simplifyShallow()
    }
}
class AddScalar : Scalar {
    var a:[Scalar]
    init(_ chain:[Scalar]) {a=chain;super.init(1)}
    init(_ chain:[Scalar],_ s:Int) {a=chain;super.init(s)}
    override func deepcopy() -> Scalar {return AddScalar(a.map{g in g.deepcopy()},c)}
    override func copy() -> Scalar {return AddScalar(a,c)}
    override func eval() -> Double {var e=0.0;for n in a {e+=n.eval()};return e*Double(c)}
    override func simplifyShallow() -> Scalar {
        if c==0 {return Scalar(0)}
        var b:[Scalar]=a.map{g in g.deepcopy()}
        var n=0
        while n<b.count {
            if let bd = b[n] as? AddScalar {
                for g in bd.a {g.c*=bd.c;b.append(g)}
                b.remove(at:n)
            } else if b[n].c==0 {b.remove(at:n)}
            else {n=n+1}
        }
        n=0
        while n<b.count {
            var m=n+1
            while m<b.count {
                if coefEqual(b[n],b[m]) {
                    b[n].c+=b[m].c
                    b.remove(at:m);m=m-1
                    if b[n].c==0 {b.remove(at:n);n=n-1;m=m-1}
                }
                m=m+1
            }
            n=n+1
        }
        let gc=gcf(a.map{$0.c})
        n=0
        while n<b.count {b[n].c/=gc}
        if b.count==0 {return Scalar(0)}
        if b.count==1 {b[0].c*=c*gc;return b[0]}
        return AddScalar(b,c*gc)
    }
    override func simplifyBroad() -> Scalar {return AddScalar(a.map{$0.simplifyBroad()},c).simplifyShallow()}
    override func simplifyNarrow() -> Scalar {
        //simplify broad, then start in on factoring.
        return Scalar(5)
    }
}
class MultScalar : Scalar {
    var a:[Scalar]
    init(_ chain:[Scalar]) {a=chain;super.init(1)}
    init(_ chain:[Scalar],_ s:Int) {a=chain;super.init(s)}
    override func deepcopy() -> Scalar {return MultScalar(a.map{g in g.deepcopy()},c)}
    override func copy() -> Scalar {return MultScalar(a,c)}
    override func eval() -> Double {var e=1.0;for n in a {e*=n.eval()};return e*Double(c)}
    override func simplifyShallow() -> Scalar {
        var b:[Scalar]=a.map{g in g.deepcopy()}
        var d:Int=c
        var n=0
        while n<b.count {
            d*=b[n].c;b[n].c=1
            if let bd = b[n] as? MultScalar {
                b.append(contentsOf:bd.a)
                b.remove(at:n)
            } else if type(of:b[n]) === Scalar.self {
                b.remove(at:n)
            } else {n=n+1}
        }
        n=0
        while n<b.count {
            var m=n+1
            while m<b.count {
                if let bn=b[n] as? PowScalar, let bm=b[m] as? PowScalar, type(of:bn.b) === Scalar.self && type(of:bm.b) === Scalar.self {
                    let gc = gcf(bn.b.c,bm.b.c)
                    if gc != 1 {
                        b.append(pow(Scalar(gc),bn.e+bm.e));d*=b[b.count-1].c;b[b.count-1].c=1;
                        if type(of:b[b.count-1]) === Scalar.self {b.remove(at:b.count-1)}
                        if bm.b.c==gc {b.remove(at:m);m=m-1}
                        else {bm.b.c /= gc}
                        if bn.b.c==gc {b.remove(at:n);n=n-1;m=m-1}
                        else {bn.b.c /= gc}
                    }
                } else {
                    let bnb = b[n] is PowScalar ? (b[n] as! PowScalar).b : b[n]
                    let bne = b[n] is PowScalar ? (b[n] as! PowScalar).e : Scalar(1)
                    let bmb = b[m] is PowScalar ? (b[m] as! PowScalar).b : b[m]
                    let bme = b[m] is PowScalar ? (b[m] as! PowScalar).e : Scalar(1)
                    if (bnb==bmb) {
                        b[n] = pow(bnb,bne+bme);d*=b[n].c;b[n].c=1;
                        b.remove(at:m);m=m-1
                        if type(of:b[n]) === Scalar.self {b.remove(at:n);n=n-1;m=m-1}
                    }
                }
                m=m+1
            }
            n=n+1
        }
        if c==0       {return Scalar(0)}
        if b.count==0 {return Scalar(d)}
        if b.count==1 {b[0].c=d;return b[0]}
        return MultScalar(b,d)
    }
    override func simplifyNarrow() -> Scalar {return MultScalar(a.map{$0.simplifyNarrow()},c).simplifyShallow()}
    override func simplifyBroad() -> Scalar {return MultScalar(a.map{$0.simplifyBroad()},c).distribute()}
    func distribute() -> Scalar {
        var accu:[Scalar]=[Scalar(1)]
        for bd in a {
            if let bd = bd as? AddScalar {
                var bccu:[Scalar]=[]
                for q in accu {for y in bd.a {bccu.append(q*y*Scalar(bd.c))}}
                accu=bccu
            } else if !(type(of:bd) === Scalar.self) {
                for q in 0..<accu.count {accu[q] = accu[q]*bd}
            }
        }
        return AddScalar(accu,c).simplifyShallow()
    }
}


class SpecialRef : Scalar {
    var id:Int
    var local:Int
    init(_ i:Int,_ l:Int) {id=i;local=l;super.init(1)}
    init(_ i:Int,_ l:Int,_ s:Int) {id=i;local=l;super.init(s)}
    override func deepcopy() -> Scalar {return SpecialRef(id,local,c)}
    override func copy() -> Scalar {return SpecialRef(id,local,c)}
}

class Abs : Scalar {
    var a:Scalar
    init(_ gs:Scalar) {a=gs;super.init(1)}
    init(_ gs:Scalar,_ s:Int) {a=gs;super.init(s)}
    override func deepcopy() -> Scalar {return Abs(a.deepcopy(),c)}
    override func copy() -> Scalar {return Abs(a,c)}
    override func eval() -> Double {return abs(a.eval())}
}
class Magnitude2 : Scalar {
    var a:Vector2
    init(_ gs:Vector2) {a=gs;super.init(1)}
    init(_ gs:Vector2,_ s:Int) {a=gs;super.init(s)}
    override func deepcopy() -> Scalar {return Magnitude2(a.deepcopy(),c)}
    override func copy() -> Scalar {return Magnitude2(a,c)}
    override func eval() -> Double {
        let x=a.eval()
        return sqrt(x.x*x.x+x.y*x.y)*Double(c)
    }
}
class Magnitude3 : Scalar {
    var a:Vector3
    init(_ gs:Vector3) {a=gs;super.init(1)}
    init(_ gs:Vector3,_ s:Int) {a=gs;super.init(s)}
    override func deepcopy() -> Scalar {return Magnitude3(a.deepcopy(),c)}
    override func copy() -> Scalar {return Magnitude3(a,c)}
    override func eval() -> Double {
        let x=a.eval()
        return sqrt(x.x*x.x+x.y*x.y+x.z*x.z)*Double(c)
    }
}


class ScalarProd2 : Vector2 {
    var a:Scalar
    var b:Vector2
    init(_ x:Scalar,_ y:Vector2) {a=x;b=y}
    override func deepcopy() -> Vector2 {return ScalarProd2(a.deepcopy(),b.deepcopy())}
    override func copy() -> Vector2 {return ScalarProd2(a,b)}
    override func eval() -> Vec2 {return b.eval()*a.eval()}
}
class ScalarProd3 : Vector3 {
    var a:Scalar
    var b:Vector3
    init(_ x:Scalar,_ y:Vector3) {a=x;b=y}
    override func deepcopy() -> Vector3 {return ScalarProd3(a.deepcopy(),b.deepcopy())}
    override func copy() -> Vector3 {return ScalarProd3(a,b)}
    override func eval() -> Vec3 {return b.eval()*a.eval()}
}
class DotProd2 : Scalar {
    var a:Vector2
    var b:Vector2
    init(_ x:Vector2,_ y:Vector2) {a=x;b=y;super.init(1)}
    init(_ x:Vector2,_ y:Vector2,_ s:Int) {a=x;b=y;super.init(s)}
    override func deepcopy() -> Scalar {return DotProd2(a.deepcopy(),b.deepcopy(),c)}
    override func copy() -> Scalar {return DotProd2(a,b,c)}
    override func eval() -> Double {
        let x=a.eval()
        let y=b.eval()
        return (x.x*y.x+x.y*y.y)*Double(c)
    }
}
class DotProd3 : Scalar {
    var a:Vector3
    var b:Vector3
    init(_ x:Vector3,_ y:Vector3) {a=x;b=y;super.init(1)}
    init(_ x:Vector3,_ y:Vector3,_ s:Int) {a=x;b=y;super.init(s)}
    override func deepcopy() -> Scalar {return DotProd3(a.deepcopy(),b.deepcopy(),c)}
    override func copy() -> Scalar {return DotProd3(a,b,c)}
    override func eval() -> Double {
        let x=a.eval()
        let y=b.eval()
        return (x.x*y.x+x.y*y.y+x.z*y.z)*Double(c)
    }
}
class CrossProd2 : Scalar {
    var a:Vector2
    var b:Vector2
    init(_ x:Vector2,_ y:Vector2) {a=x;b=y;super.init(1)}
    init(_ x:Vector2,_ y:Vector2,_ s:Int) {a=x;b=y;super.init(s)}
    override func deepcopy() -> Scalar {return CrossProd2(a.deepcopy(),b.deepcopy(),c)}
    override func copy() -> Scalar {return CrossProd2(a,b,c)}
    override func eval() -> Double {
        let x=a.eval()
        let y=b.eval()
        return (x.x*y.y-x.y*y.x)*Double(c)
    }
}
class CrossProd3 : Vector3 {
    var a:Vector3
    var b:Vector3
    init(_ x:Vector3,_ y:Vector3) {a=x;b=y}
    init(_ x:Vector3,_ y:Vector3,_ s:Int) {a=x;b=y}
    override func deepcopy() -> Vector3 {return CrossProd3(a.deepcopy(),b.deepcopy())}
    override func copy() -> Vector3 {return CrossProd3(a,b)}
    override func eval() -> Vec3 {
        let x=a.eval()
        let y=b.eval()
        return Vec3(x.y*y.z-x.z*y.y,x.z*y.x-x.x*y.z,x.x*y.y-x.y*y.x)
    }
}


class AddVector2 : Vector2 {
    var a:[Vector2]
    init(_ chain:[Vector2]) {a=chain}
    override func deepcopy() -> Vector2 {return AddVector2(a.map{g in g.deepcopy()})}
    override func copy() -> Vector2 {return AddVector2(a)}
    override func eval() -> Vec2 {var e=Vec2(0,0);for n in a {e=e+n.eval()};return e}
}
class AddVector3 : Vector3 {
    var a:[Vector3]
    init(_ chain:[Vector3]) {a=chain}
    override func deepcopy() -> Vector3 {return AddVector3(a.map{g in g.deepcopy()})}
    override func copy() -> Vector3 {return AddVector3(a)}
    override func eval() -> Vec3 {var e=Vec3(0,0,0);for n in a {e=e+n.eval()};return e}
}



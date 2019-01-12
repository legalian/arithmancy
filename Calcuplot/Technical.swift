//
//  Technical.swift
//  Calcuplot
//
//  Created by Parker on 11/28/18.
//  Copyright © 2018 Parker. All rights reserved.
//

import Foundation


protocol Scalar {
    var c:Int {get set}
    func deepcopy() -> Scalar
    func copy() -> Scalar
    func eval() -> Double
    func simplifyNarrow()  -> Scalar
    func simplifyBroad()   -> Scalar
    func simplifyShallow() -> Scalar
    func derivative(_ va:String) -> Scalar
    func latex() -> String
}
protocol Vector2 {
    func deepcopy() -> Vector2
    func copy() -> Vector2
    func eval() -> Vec2
    func separate() -> (Scalar,Scalar)
    func derivative(_ va:String) -> Vector2
    func latex() -> String
}
protocol Vector3 {
    func deepcopy() -> Vector3
    func copy() -> Vector3
    func eval() -> Vec3
    func separate() -> (Scalar,Scalar,Scalar)
    func derivative(_ va:String) -> Vector3
    func latex() -> String
}
class Constant : Scalar {
    var c: Int
    init(_ a:Int) {c=a}
    func deepcopy() -> Scalar {return Constant(c)}
    func copy() -> Scalar {return Constant(c)}
    func eval() -> Double {return Double(c)}
    func simplifyNarrow()  -> Scalar {return deepcopy()}
    func simplifyBroad()   -> Scalar {return deepcopy()}
    func simplifyShallow() -> Scalar {return deepcopy()}
    func derivative(_ va:String) -> Scalar {return Constant(0)}
    func latex() -> String {return String(c)}
}
class Assemble2 : Vector2 {
    var x:Scalar
    var y:Scalar
    init(_ a:Scalar,_ b:Scalar) {x=a;y=b}
    func deepcopy() -> Vector2 {return Assemble2(x.deepcopy(),y.deepcopy())}
    func copy() -> Vector2 {return Assemble2(x,y)}
    func eval() -> Vec2 {return Vec2(x.eval(),y.eval())}
    func separate() -> (Scalar, Scalar) {return (x,y)}
    func derivative(_ va: String) -> Vector2 {return Assemble2(x.derivative(va),y.derivative(va))}
    func latex() -> String {return "[^{"+x.latex()+"}_{"+y.latex()+"}]"}
}
class Assemble3 : Vector3 {
    var x:Scalar
    var y:Scalar
    var z:Scalar
    init(_ a:Scalar,_ b:Scalar,_ c:Scalar) {x=a;y=b;z=c}
    func deepcopy() -> Vector3 {return Assemble3(x.deepcopy(),y.deepcopy(),z.deepcopy())}
    func copy() -> Vector3 {return Assemble3(x,y,z)}
    func eval() -> Vec3 {return Vec3(x.eval(),y.eval(),z.eval())}
    func separate() -> (Scalar, Scalar, Scalar) {return (x,y,z)}
    func derivative(_ va: String) -> Vector3 {return Assemble3(x.derivative(va),y.derivative(va),z.derivative(va))}
    func latex() -> String {return "[^{_{"+x.latex()+"}}_{^{"+y.latex()+"}_{"+z.latex()+"}}]"}
}




class PowScalar : Scalar {
    var c:Int=1
    var e:Scalar
    var b:Scalar
    init(_ bs:Scalar,_ es:Scalar) {e=es;b=bs}
    init(_ bs:Scalar,_ es:Scalar,_ s:Int) {e=es;b=bs;c=s}
    func deepcopy() -> Scalar {return PowScalar(b.deepcopy(),e.deepcopy(),c)}
    func copy() -> Scalar {return PowScalar(b,e,c)}
    
    func eval() -> Double {return Double(c)*pow(b.eval(),e.eval());}
    func simplifyShallow() -> Scalar {
        if c==0 {return Constant(0)}
        if let bb=b as? MultScalar {return MultScalar(bb.a.map{pow($0,e)},c).simplifyShallow()}
        if let be=b as? PowScalar {return pow(be.b,e*be.e)}
        let shet = deepcopy() as! PowScalar
        if let e = asint(shet.e) {
            if shet.b.c<0 {
                shet.b.c = -shet.b.c
                if e%2 != 0 {shet.c = -shet.c}
            }
        }
        if let b = asint(shet.b) {
            if b==1 {return Constant(shet.c)}
            if b==0 {return Constant(0)}//ok obviously this is a problem- dividing by zero or 0^0 are both suspects here
            if let e = asint(shet.e), e>=0 {return Constant(pow(b,e))}
        }
        if let e = asint(shet.e) {
            if e == 0 {return Constant(shet.c)}
            if e == 1 {var bb=shet.b.deepcopy();bb.c*=c;return bb}
            if e > 1 {
                shet.c = shet.c*pow(shet.b.c,e)
                shet.b.c = 1
            }
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
                if b==1 {return Constant(c)}
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
    func simplifyNarrow() -> Scalar {return PowScalar(b.simplifyNarrow(),e.simplifyBroad(),c).simplifyShallow()}
    func simplifyBroad()  -> Scalar {
        let vmr = simplifyNarrow()
        return MultScalar(asmultchain(vmr).map{ga in
            if let g=ga as? PowScalar {
                if let ge = asint(g.e) {
                    if ge >  1 {return MultScalar([Scalar](repeating:g.b,count:ge),g.c).distribute()}
                    if ge < -1 {return PowScalar(MultScalar([Scalar](repeating:g.b,count:-ge)),Constant(-1),g.c)}
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
    func latex() -> String {
        if let (n,d) = asrational(e) {
            if n == -1 {
                if d == 2 {return "\\frac{"+String(c)+"}{\\sqrt{"+b.latex()+"}}"}
                if d == 1 {return "\\frac{"+String(c)+"}{"+b.latex()+"}"}
                var g = e.copy()
                g.c *= -1
                if b is AddScalar || b is MultScalar || b is PowScalar || b is Integral || b is DotProd2 || b is DotProd3 || b is CrossProd2 || b.c != 1 && !(b is Constant) {
                    return "\\frac{"+String(c)+"}{("+b.latex()+")^{"+g.latex()+"}}"
                }
                return "\\frac{"+String(c)+"}{"+b.latex()+"^{"+g.latex()+"}}"
            }
            if n == 1 && d == 2 {
                return "\\sqrt{"+b.latex()+"}"
            }
        }
        if b is AddScalar || b is MultScalar || b is PowScalar || b is Integral || b is DotProd2 || b is DotProd3 || b is CrossProd2 || b.c != 1 && !(b is Constant) {
            if c == -1 {return "-("+b.latex()+")^{"+e.latex()+"}"}
            else if c != 1 {return String(c)+"("+b.latex()+")^{"+e.latex()+"}"}
            else {return "("+b.latex()+")^{"+e.latex()+"}"}
        }
        if c == -1 {return "-"+b.latex()+"^{"+e.latex()+"}"}
        else if c != 1 {return String(c)+b.latex()+"^{"+e.latex()+"}"}
        else {return b.latex()+"^{"+e.latex()+"}"}
    }
    func derivative(_ va: String) -> Scalar {return pow(b,e+Constant(-1),c)*b.derivative(va) + pow(b,e,c)*LnScalar(b)*e.derivative(va)}
}
class AddScalar : Scalar {
    var c : Int = 1
    var a:[Scalar]
    init(_ chain:[Scalar]) {a=chain}
    init(_ chain:[Scalar],_ s:Int) {a=chain;c=s}
    func deepcopy() -> Scalar {return AddScalar(a.map{g in g.deepcopy()},c)}
    func copy() -> Scalar {return AddScalar(a,c)}
    func eval() -> Double {var e=0.0;for n in a {e+=n.eval()};return e*Double(c)}
    func simplifyShallow() -> Scalar {
        if c==0 {return Constant(0)}
        var b : [Scalar] = []
        var recur: (([Scalar],Int) -> Void)!
        recur = {f,cc in
            for n in f {
                if let n=n as? AddScalar {
                    recur(n.a,n.c)
                } else if n.c != 0 {
                    var ce = n.deepcopy()
                    ce.c*=cc
                    b.append(ce)
                }
            }
        }
        recur(a,1)
        b = doubleRemap(b,{x,y in
            if coefEqual(x,y) {
                var xx = x.copy()
                xx.c+=y.c
                return (xx,nil,nil)
            }
            return (x,y,nil)
        })
        if b.count==0 {return Constant(0)}
        if b.count==1 {b[0].c*=c;return b[0]}
        return AddScalar(b,c)
    }
    func simplifyBroad() -> Scalar {return AddScalar(a.map{$0.simplifyBroad()},c).simplifyShallow()}
    func simplifyNarrow() -> Scalar {
        let fo = simplifyBroad()
        guard let f=fo as? AddScalar else {return fo}
        var gc = gcf(f.a);gc.c*=f.c
        return gc*AddScalar(f.a.map{h in (h*pow(gc,-1)).simplifyNarrow()}).simplifyShallow()
    }
    func latex() -> String {
        var res = ""
        if a.count==0 {return "0"}
        for g in 0..<a.count {
            if a[g].c>=0 && g>0 {res=res+"+"}
            if a[g].c<0 && g>0 {res=res+"-"}
            var t = a[g].copy()
            if t.c<0 {t.c *= -1}
            res=res+t.latex()
        }
        if c == -1 {return "-("+res+")"}
        else if c != 1 {return String(c)+"("+res+")"}
        else {return res}
    }
    func derivative(_ va: String) -> Scalar {return a.reduce(Constant(0)){a,b in a+b.derivative(va)}*c}
}
class MultScalar : Scalar {
    var c : Int = 1
    var a:[Scalar]
    init(_ chain:[Scalar]) {a=chain}
    init(_ chain:[Scalar],_ s:Int) {a=chain;c=s}
    func deepcopy() -> Scalar {return MultScalar(a.map{g in g.deepcopy()},c)}
    func copy() -> Scalar {return MultScalar(a,c)}
    func eval() -> Double {var e=1.0;for n in a {e*=n.eval()};return e*Double(c)}
    func simplifyShallow() -> Scalar {
        var conse : [(Scalar,Int,Int)] = []
        var conco : [(Int,Int)] = [(c,1)]
        var expba : [Scalar] = []
        var b : [Scalar] = []
        var d = 1
        var recur: (([Scalar]) -> Void)!
        recur = {f in
            for n in f {
                if n.c != 1 {conco.append((n.c,1))}
                if asint(n) != nil {continue}
                if let a=n as? MultScalar {recur(a.a)}
                var t=n.deepcopy();t.c=1
                var (mb,me) = aspower(t)
                if let (nu,de) = asrational(me) {
                    if let a = asint(mb) {
                        if (nu<0) {conco.append((pow(a,-nu),-de))}
                        else {conco.append((pow(a,nu),de))}
                    } else {
                        if mb.c != 1 {
                            if (nu<0) {conco.append((pow(mb.c,-nu),-de))}
                            else {conco.append((pow(mb.c,nu),de))}
                            mb.c=1
                        }
                        conse.append((mb,nu,de))
                    }
                } else {expba.append(me*LnScalar(mb))}
            }
        }
        recur(a)
        for y in doubleRemap(doubleRemap(conco.filter{a in a.0 != 1},{a,b in
            let gc = gcf(a.0,b.0)
            if gc==1 {return (a,b,nil)}
            let gcc = gcf(a.1+b.1,a.1*b.1)
            var a=a,b=b
            a.0/=gc ; b.0/=gc
            if a.1+b.1>0 {return (a.0==1 ?nil:a,b.0==1 ?nil:b,(pow(gc,(a.1+b.1)/gcc),(a.1*b.1)/gcc))}
            if a.1+b.1<0 {return (a.0==1 ?nil:a,b.0==1 ?nil:b,(pow(gc,-(a.1+b.1)/gcc),-(a.1*b.1)/gcc))}
            return (a.0==1 ?nil:a,b.0==1 ?nil:b,nil)
        }),{a,b in
            if a.1 != b.1 {return (a,b,nil)}
            var a=a
            a.0 *= b.0
            return (a,nil,nil)
        }) {
            var cel = pow(Constant(y.0),exactdivide(1,y.1))
            d*=cel.c;cel.c=1;
            if asint(cel) != nil {continue}
            b.append(cel)
        }
        for y in doubleRemap(conse,{a,b in
            if !(a.0 == b.0) {
                var a=a
                (a.1,a.2) = (a.1*b.2+b.1*a.2,a.2*b.2)
                return (a,nil,nil)
            }
            return (a,b,nil)
        }) {
            let cel = pow(y.0,exactdivide(y.1,y.2))
            if let a = asint(cel) {d*=a;continue}
            b.append(cel)
        }
        for y in asaddchain(AddScalar(expba).simplifyShallow()) {
            b.append(PowScalar(SpecialRef("e"),y))
        }
        if d==0       {return Constant(0)}
        if b.count==0 {return Constant(d)}
        if b.count==1 {b[0].c=d;return b[0]}
        return MultScalar(b,d)
    }
    func simplifyNarrow() -> Scalar {return MultScalar(a.map{$0.simplifyNarrow()},c).simplifyShallow()}
    func simplifyBroad() -> Scalar {return MultScalar(a.map{$0.simplifyBroad()},c).distribute()}
    func distribute() -> Scalar {
        var accu:[Scalar]=[Constant(1)]
        for bd in a {
            if let bd = bd as? AddScalar {
                var bccu:[Scalar]=[]
                for q in accu {for y in bd.a {bccu.append(q*y*Constant(bd.c))}}
                accu=bccu
            } else {
                for q in 0..<accu.count {accu[q] = accu[q]*bd}
            }
        }
        return AddScalar(accu,c).simplifyShallow()
    }
    func latex() -> String {
        a.sort(by:{x,y in
            let a = x is Integral ?0:x is AddScalar ?2:x is MultScalar ?2:x is SpecialRef ?3:x is Constant ?4:1
            let b = y is Integral ?0:y is AddScalar ?2:y is MultScalar ?2:y is SpecialRef ?3:y is Constant ?4:1
            return a>=b
        });
        var ayy:[Scalar]=[]
        var byy:[Scalar]=[]
        for g in a {
            if let g=g as? PowScalar, let (nad,dad) = asrational(g.e), nad<0 {
                if g.c != 1 {ayy.append(Constant(g.c))}
                byy.append(pow(g.b,exactdivide(-nad,dad)))
            } else {ayy.append(g)}
        }
        if byy.count==1 {
            if ayy.count==1 {
                var lc = ayy[0].copy()
                lc.c *= c
                return "\\frac{"+lc.latex()+"}{"+byy[0].latex()+"}"
            }
            return "\\frac{"+MultScalar(ayy,c).latex()+"}{"+byy[0].latex()+"}"
        } else if byy.count>1 {
            if ayy.count==1 {
                var lc = ayy[0].copy()
                lc.c *= c
                return "\\frac{"+lc.latex()+"}{"+MultScalar(byy).latex()+"}"
            }
            return "\\frac{"+MultScalar(ayy,c).latex()+"}{"+MultScalar(byy).latex()+"}"
        }
        
        //negative fraction
        //negative constant times fraction
        //constant times fraction
        //constant fraction in multchain
        
        
        var res = ""
        if a.count==0 {return String(c)}
        if c == -1 {res="-"}
        else if c != 1 {res = String(c)}
        for g in 0..<a.count {
            if (a[g] is Integral && g != a.count-1) || a[g] is AddScalar || a[g] is MultScalar || type(of:a[g]) == Scalar.self
            {res = res+"("+a[g].latex()+")"}
            else {res = res+a[g].latex()}
        }
        return res
    }
    func derivative(_ va: String) -> Scalar {
        var acc : Scalar = Constant(0)
        for g in 0..<a.count {
            var bcc = a[g].derivative(va)*c
            for d in 0..<a.count {
                if g != d {bcc = bcc * a[d]}
            }
            acc = acc + bcc
        }
        return acc
    }
}


class SpecialRef : Scalar {
    func eval() -> Double {
        <#code#>
    }
    func simplifyNarrow() -> Scalar {return deepcopy()}
    func simplifyBroad() -> Scalar {return deepcopy()}
    func simplifyShallow() -> Scalar {return deepcopy()}
    
    var c : Int = 1
    var va:String
    init(_ i:String) {va=i}
    init(_ i:String,_ s:Int) {va=i;c=s}
    func deepcopy() -> Scalar {return SpecialRef(va,c)}
    func copy() -> Scalar {return SpecialRef(va,c)}
    func latex() -> String {
        if c == -1 {return "-"+va}
        if c != 1 {return String(c)+va}
        return va
    }
    func derivative(_ vsa: String) -> Scalar {
        if va==vsa {return Constant(c)}
        return Constant(0)
    }
}

class Abs : Scalar {
    var c : Int = 1
    var a:Scalar
    init(_ gs:Scalar) {a=gs}
    init(_ gs:Scalar,_ s:Int) {a=gs;c=s}
    func deepcopy() -> Scalar {return Abs(a.deepcopy(),c)}
    func copy() -> Scalar {return Abs(a,c)}
    func eval() -> Double {return abs(a.eval())}
    func latex() -> String {
        if c == -1 {return "-|"+a.latex()+"|"}
        if c != 1 {return String(c)+"|"+a.latex()+"|"}
        return "|"+a.latex()+"|"
    }
    func simplifyNarrow() -> Scalar {
        let g = a.simplifyNarrow()
        return MultScalar(asmultchain(g).map{a in Abs(a)},g.c*c).simplifyShallow()
    }
    func simplifyBroad() -> Scalar {return Abs(a.simplifyBroad())}
    func simplifyShallow() -> Scalar {return deepcopy()}
    func derivative(_ va: String) -> Scalar {return a.derivative(va)*c*a/Abs(a)}
}
class Magnitude2 : Scalar {
    var c : Int = 1
    var a:Vector2
    init(_ gs:Vector2) {a=gs}
    init(_ gs:Vector2,_ s:Int) {a=gs;c=s}
    func deepcopy() -> Scalar {return Magnitude2(a.deepcopy(),c)}
    func copy() -> Scalar {return Magnitude2(a,c)}
    func eval() -> Double {
        let x=a.eval()
        return sqrt(x.x*x.x+x.y*x.y)*Double(c)
    }
    func latex() -> String {
        if c == -1 {return "-‖"+a.latex()+"‖"}
        if c != 1 {return String(c)+"‖"+a.latex()+"‖"}
        return "‖"+a.latex()+"‖"
    }
    func simplifyNarrow() -> Scalar {return simplifyShallow().simplifyNarrow()}
    func simplifyBroad() -> Scalar {return simplifyShallow().simplifyBroad()}
    func simplifyShallow() -> Scalar {
        let (x,y) = a.separate()
        return pow(pow(x,2)+pow(y,2),exactdivide(1,2),c)
    }
    func derivative(_ va: String) -> Scalar {return simplifyShallow().derivative(va)}
}
class Magnitude3 : Scalar {
    var c : Int = 1
    var a:Vector3
    init(_ gs:Vector3) {a=gs}
    init(_ gs:Vector3,_ s:Int) {a=gs;c=s}
    func deepcopy() -> Scalar {return Magnitude3(a.deepcopy(),c)}
    func copy() -> Scalar {return Magnitude3(a,c)}
    func eval() -> Double {
        let x=a.eval()
        return sqrt(x.x*x.x+x.y*x.y+x.z*x.z)*Double(c)
    }
    func latex() -> String {
        if c == -1 {return "-‖"+a.latex()+"‖"}
        if c != 1 {return String(c)+"‖"+a.latex()+"‖"}
        return "‖"+a.latex()+"‖"
    }
    func simplifyNarrow() -> Scalar {return simplifyShallow().simplifyNarrow()}
    func simplifyBroad() -> Scalar {return simplifyShallow().simplifyBroad()}
    func simplifyShallow() -> Scalar {
        let (x,y,z) = a.separate()
        return pow(pow(x,2)+pow(y,2)+pow(z,2),exactdivide(1,2),c)
    }
    func derivative(_ va: String) -> Scalar {return simplifyShallow().derivative(va)}
}



class ScalarProd2 : Vector2 {
    var a:Scalar
    var b:Vector2
    init(_ x:Scalar,_ y:Vector2) {a=x;b=y}
    func deepcopy() -> Vector2 {return ScalarProd2(a.deepcopy(),b.deepcopy())}
    func copy() -> Vector2 {return ScalarProd2(a,b)}
    func eval() -> Vec2 {return b.eval()*a.eval()}
    func latex() -> String {
        if let a = a as? MultScalar {
            if !(a.a[0] is Integral) {return a.latex()+b.latex()}
        }
        if a is Integral || a is DotProd2 || a is DotProd3 {
            if b is Integral2 || b is AddVector2 {
                return "("+a.latex()+")("+b.latex()+")"
            }
            return "("+a.latex()+")"+b.latex()
        }
        if b is Integral2 || b is AddVector2 {
            return a.latex()+"("+b.latex()+")"
        }
        return a.latex()+b.latex()
    }
    func separate() -> (Scalar, Scalar) {
        let (x,y) = b.separate()
        return (a*x,a*y)
    }
    func derivative(_ va: String) -> Vector2 {return ScalarProd2(a,b.derivative(va)) + ScalarProd2(a.derivative(va),b)}
}
class ScalarProd3 : Vector3 {
    var a:Scalar
    var b:Vector3
    init(_ x:Scalar,_ y:Vector3) {a=x;b=y}
    func deepcopy() -> Vector3 {return ScalarProd3(a.deepcopy(),b.deepcopy())}
    func copy() -> Vector3 {return ScalarProd3(a,b)}
    func eval() -> Vec3 {return b.eval()*a.eval()}
    func latex() -> String {
        if let a = a as? MultScalar {
            if !(a.a[0] is Integral) {return a.latex()+b.latex()}
        }
        if a is Integral || a is DotProd2 || a is DotProd3 {
            if b is Integral3 || b is AddVector3 {
                return "("+a.latex()+")("+b.latex()+")"
            }
            return "("+a.latex()+")"+b.latex()
        }
        if b is Integral3 || b is AddVector3 {
            return a.latex()+"("+b.latex()+")"
        }
        return a.latex()+b.latex()
    }
    func separate() -> (Scalar, Scalar, Scalar) {
        let (x,y,z) = b.separate()
        return (a*x,a*y,a*z)
    }
    func derivative(_ va: String) -> Vector3 {return ScalarProd3(a,b.derivative(va)) + ScalarProd3(a.derivative(va),b)}
}
class DotProd2 : Scalar {
    var c : Int = 1
    var a:Vector2
    var b:Vector2
    init(_ x:Vector2,_ y:Vector2) {a=x;b=y}
    init(_ x:Vector2,_ y:Vector2,_ s:Int) {a=x;b=y;c=s}
    func deepcopy() -> Scalar {return DotProd2(a.deepcopy(),b.deepcopy(),c)}
    func copy() -> Scalar {return DotProd2(a,b,c)}
    func eval() -> Double {
        let x=a.eval()
        let y=b.eval()
        return (x.x*y.x+x.y*y.y)*Double(c)
    }
    func latex() -> String {
        return a.latex()+"·"+b.latex()
    }
    func simplifyNarrow() -> Scalar {return simplifyShallow().simplifyNarrow()}
    func simplifyBroad() -> Scalar {return simplifyShallow().simplifyBroad()}
    func simplifyShallow() -> Scalar {
        let (x1,y1) = a.separate()
        let (x2,y2) = b.separate()
        return AddScalar([x1*x2,y1*y2],c)
    }
    func derivative(_ va: String) -> Scalar {return DotProd2(a,b.derivative(va),c) + DotProd2(a.derivative(va),b,c)}
}
class DotProd3 : Scalar {
    var c : Int = 1
    var a:Vector3
    var b:Vector3
    init(_ x:Vector3,_ y:Vector3) {a=x;b=y}
    init(_ x:Vector3,_ y:Vector3,_ s:Int) {a=x;b=y;c=s}
    func deepcopy() -> Scalar {return DotProd3(a.deepcopy(),b.deepcopy(),c)}
    func copy() -> Scalar {return DotProd3(a,b,c)}
    func eval() -> Double {
        let x=a.eval()
        let y=b.eval()
        return (x.x*y.x+x.y*y.y+x.z*y.z)*Double(c)
    }
    func latex() -> String {
        return a.latex()+"·"+b.latex()
    }
    func simplifyNarrow() -> Scalar {return simplifyShallow().simplifyNarrow()}
    func simplifyBroad() -> Scalar {return simplifyShallow().simplifyBroad()}
    func simplifyShallow() -> Scalar {
        let (x1,y1,z1) = a.separate()
        let (x2,y2,z2) = b.separate()
        return AddScalar([x1*x2,y1*y2,z1*z2],c)
    }
    func derivative(_ va: String) -> Scalar {return DotProd3(a,b.derivative(va),c) + DotProd3(a.derivative(va),b,c)}
}
class CrossProd2 : Scalar {
    var c : Int = 1
    var a:Vector2
    var b:Vector2
    init(_ x:Vector2,_ y:Vector2) {a=x;b=y}
    init(_ x:Vector2,_ y:Vector2,_ s:Int) {a=x;b=y;c=s}
    func deepcopy() -> Scalar {return CrossProd2(a.deepcopy(),b.deepcopy(),c)}
    func copy() -> Scalar {return CrossProd2(a,b,c)}
    func eval() -> Double {
        let x=a.eval()
        let y=b.eval()
        return (x.x*y.y-x.y*y.x)*Double(c)
    }
    func latex() -> String {
        return a.latex()+"×"+b.latex()
    }
    func simplifyNarrow() -> Scalar {return simplifyShallow().simplifyNarrow()}
    func simplifyBroad() -> Scalar {return simplifyShallow().simplifyBroad()}
    func simplifyShallow() -> Scalar {
        let (x1,y1) = a.separate()
        let (x2,y2) = b.separate()
        return AddScalar([x1*y2,y1*x2 * -1],c)
    }
    func derivative(_ va: String) -> Scalar {return CrossProd2(a,b.derivative(va),c) - CrossProd2(a.derivative(va),b,c)}//double check this
}
class CrossProd3 : Vector3 {
    var a:Vector3
    var b:Vector3
    init(_ x:Vector3,_ y:Vector3) {a=x;b=y}
    init(_ x:Vector3,_ y:Vector3,_ s:Int) {a=x;b=y}
    func deepcopy() -> Vector3 {return CrossProd3(a.deepcopy(),b.deepcopy())}
    func copy() -> Vector3 {return CrossProd3(a,b)}
    func eval() -> Vec3 {
        let x=a.eval()
        let y=b.eval()
        return Vec3(x.y*y.z-x.z*y.y,x.z*y.x-x.x*y.z,x.x*y.y-x.y*y.x)
    }
    func latex() -> String {
        return a.latex()+"×"+b.latex()
    }
    func separate() -> (Scalar, Scalar, Scalar) {
        let (x1,y1,z1)=a.separate()
        let (x2,y2,z2)=b.separate()
        return (y1*z2-z1*y2,z1*x2-x1*z2,x1*y2-y1*x2)
    }
    func derivative(_ va: String) -> Vector3 {return CrossProd3(a,b.derivative(va)) - CrossProd3(a.derivative(va),b)}
}


class AddVector2 : Vector2 {
    var a:[Vector2]
    init(_ chain:[Vector2]) {a=chain}
    func deepcopy() -> Vector2 {return AddVector2(a.map{g in g.deepcopy()})}
    func copy() -> Vector2 {return AddVector2(a)}
    func eval() -> Vec2 {return a.reduce(Vec2(0,0),{a,b in a+b.eval()})}
    func latex() -> String {
        var res = ""
        if a.count==0 {return "0"}
        for g in 0..<a.count {
            if g>0 {res=res+"+"}
            res=res+a[g].latex()
        }
        return res
    }
    func separate() -> (Scalar, Scalar) {
        let h = a.map{j in j.separate()}
        return (AddScalar((0..<a.count).map{j in h[j].0}),AddScalar((0..<a.count).map{j in h[j].1}))
    }
    func derivative(_ va: String) -> Vector2 {return AddVector2(a.map{j in j.derivative(va)})}
}
class AddVector3 : Vector3 {
    var a:[Vector3]
    init(_ chain:[Vector3]) {a=chain}
    func deepcopy() -> Vector3 {return AddVector3(a.map{g in g.deepcopy()})}
    func copy() -> Vector3 {return AddVector3(a)}
    func eval() -> Vec3 {return a.reduce(Vec3(0,0,0),{a,b in a+b.eval()})}
    func latex() -> String {
        var res = ""
        if a.count==0 {return "0"}
        for g in 0..<a.count {
            if g>0 {res=res+"+"}
            res=res+a[g].latex()
        }
        return res
    }
    func separate() -> (Scalar, Scalar, Scalar) {
        let h = a.map{j in j.separate()}
        return (AddScalar((0..<a.count).map{j in h[j].0}),AddScalar((0..<a.count).map{j in h[j].1}),AddScalar((0..<a.count).map{j in h[j].2}))
    }
    func derivative(_ va: String) -> Vector3 {return AddVector3(a.map{j in j.derivative(va)})}
}



class LnScalar : Scalar {
    func simplifyNarrow() -> Scalar {
        return simplifyShallow();
    }
    
    func simplifyShallow() -> Scalar {
        if b == Constant(1) {return Constant(0)}
        if b == SpecialRef("e") {return Constant(1)}
        if let b=b as? PowScalar {
            if b.c != 1 {return LnScalar(Constant(b.c)) + b.e*LnScalar(b.b)}
            return b.c + b.e*LnScalar(b.b)
        }
        if b ==
    }
    func derivative(_ va: String) -> Scalar {return b.derivative(va)/b}
    
    var c : Int = 1
    var b:Scalar
    init(_ bs:Scalar) {b=bs}
    init(_ bs:Scalar,_ s:Int) {b=bs;c=s}
    func deepcopy() -> Scalar {return LnScalar(b.deepcopy(),c)}
    func copy() -> Scalar {return LnScalar(b,c)}
    func eval() -> Double {return log(b.eval())*Double(c)}
    func simplifyBroad() -> Scalar {
        return AddScalar(asmultchain(b.simplifyNarrow()).map{g in
            let (b,e) = aspower(g)
            return e*Constant(g.c)*LnScalar(b)
        }).simplifyShallow()
    }
    func latex() -> String {
        return "ln("+b.latex()+")"
    }
}


func trigolook(_ a:Int) -> Scalar {
    if a>=24 || a<0 {return trigolook(a%%24)}
    if a>=12 {return trigolook(a-12) * -1}
    if a>6   {return trigolook(6-a) * -1}
    switch (a) {
        case 0: return Constant(1)
        case 1: return (pow(Constant(6),exactdivide(1,2))+pow(Constant(2),exactdivide(1,2)))/4
        case 2: return pow(Constant(3),exactdivide(1,2))/2
        case 3: return pow(Constant(2),exactdivide(-1,2))
        case 4: return exactdivide(1,2)
        case 5: return (pow(Constant(6),exactdivide(1,2))-pow(Constant(2),exactdivide(1,2)))/4
        default: return Constant(0)
    }
}

class SinScalar : Scalar {
    var c : Int = 1
    var b:Scalar
    init(_ bs:Scalar) {b=bs}
    init(_ bs:Scalar,_ s:Int) {b=bs;c=s}
    func deepcopy() -> Scalar {return SinScalar(b.deepcopy(),c)}
    func copy() -> Scalar {return SinScalar(b,c)}
    func eval() -> Double {return sin(b.eval())*Double(c)}
    func latex() -> String {
        return "sin("+b.latex()+")"
    }
}
class CosScalar : Scalar {
    func simplifyNarrow() -> Scalar {
        CosScalar(b.simplifyBroad()).simplifyShallow()
        
    }
    
    func simplifyBroad() -> Scalar {
        CosScalar(b.simplifyBroad()).simplifyShallow()
    }
    
    func simplifyShallow() -> Scalar {
        if coefEqual(b,SpecialRef("π")) {return trigolook(b.c*12)}
        if let b=b as? MultScalar, b.a.count==2 {
            if let (n,d) = asrational(b.a[0] == SpecialRef("π") ? b.a[1] : b.a[0]),d==1||d==2||d==3||d==4||d==6||d==12,b.a[1] == SpecialRef("π") || b.a[0] == SpecialRef("π") {
                return trigolook(n*(12/d))
            }
        }
        if let b=b as? AddScalar {
            for g in 0..<b.a.count {
                if coefEqual(b,SpecialRef("π")) {
                    var h = b.a;h.remove(at:g)
                    if ((b.c%%2)==0) {return CosScalar(AddScalar(h,b.c),c).simplifyShallow()}
                    else             {return CosScalar(AddScalar(h,b.c),-c).simplifyShallow()}
                }
                if let c=b.a[g] as? MultScalar, c.a.count==2 {
                    if let (n,d) = asrational(c.a[0] == SpecialRef("π") ? c.a[1] : c.a[0]),d==1||d==2||d==3||d==4||d==6||d==12,b.a[1] == SpecialRef("π") || c.a[0] == SpecialRef("π") {
                        var h = b.a;h.remove(at:g)
                        return trigolook(n*(12/d))
                    }
                }
            }
        }
        if b.c<0 {return CosScalar(b * -1)}
        return deepcopy()
    }
    func derivative(_ va: String) -> Scalar {return SinScalar(b)*b.derivative(va)}
    
    var c : Int = 1
    var b:Scalar
    init(_ bs:Scalar) {b=bs}
    init(_ bs:Scalar,_ s:Int) {b=bs;c=s}
    func deepcopy() -> Scalar {return CosScalar(b.deepcopy(),c)}
    func copy() -> Scalar {return CosScalar(b,c)}
    func eval() -> Double {return cos(b.eval())*Double(c)}
    func latex() -> String {
        return "cos("+b.latex()+")"
    }
}



class MaxScalar : Scalar {
    var c : Int = 1
    var a:[Scalar]
    init(_ chain:[Scalar]) {a=chain}
    init(_ chain:[Scalar],_ s:Int) {a=chain;c=s}
    func deepcopy() -> Scalar {return MaxScalar(a.map{g in g.deepcopy()},c)}
    func copy() -> Scalar {return MaxScalar(a,c)}
    func eval() -> Double {var e=a[0].eval();for n in a[1..<a.count] {e=max(e,n.eval())};return e*Double(c)}
    func latex() -> String {
        var res = "max("
        if a.count==0 {return String(c)}
        if c == -1 {res="-max("}
        else if c != 1 {res = String(c)+"max("}
        for g in 0..<a.count {
            res=res+a[g].latex()
            if g>0 {res=res+","}
        }
        return res+")"
    }
    func simplifyNarrow() -> Scalar {return simplifyShallow().simplifyNarrow()}
    func simplifyBroad() -> Scalar {return simplifyShallow().simplifyBroad()}
    func simplifyShallow() -> Scalar {
        let cell = a[1..<a.count].reduce(a[0],{x,y in return (x+y+Abs(x+y * -1))*exactdivide(1,2)})
        return cell*c
    }
    func derivative(_ va: String) -> Scalar {return simplifyShallow().derivative(va)}
}
class MinScalar : Scalar {
    var c : Int = 1
    var a:[Scalar]
    init(_ chain:[Scalar]) {a=chain}
    init(_ chain:[Scalar],_ s:Int) {a=chain;c=s}
    func deepcopy() -> Scalar {return MinScalar(a.map{g in g.deepcopy()},c)}
    func copy() -> Scalar {return MinScalar(a,c)}
    func eval() -> Double {var e=a[0].eval();for n in a[1..<a.count] {e=min(e,n.eval())};return e*Double(c)}
    func latex() -> String {
        var res = "min("
        if a.count==0 {return String(c)}
        if c == -1 {res="-min("}
        else if c != 1 {res = String(c)+"min("}
        for g in 0..<a.count {
            res=res+a[g].latex()
            if g>0 {res=res+","}
        }
        return res+")"
    }
    func simplifyNarrow() -> Scalar {return simplifyShallow().simplifyNarrow()}
    func simplifyBroad() -> Scalar {return simplifyShallow().simplifyBroad()}
    func simplifyShallow() -> Scalar {
        let cell = a[1..<a.count].reduce(a[0],{x,y in return (x+y+Abs(x+y * -1,-1))*exactdivide(1,2)})
        return cell*c
    }
    func derivative(_ va: String) -> Scalar {return simplifyShallow().derivative(va)}
}

class Derivative : Scalar {
    var c : Int = 1
    var d : Scalar
    var va : String
    var t : Scalar
    init(_ ds:Scalar,_ ts:Scalar,_ vas:String) {d=ds;t=ts;va=vas}
    init(_ ds:Scalar,_ ts:Scalar,_ vas:String,_ s:Int) {d=ds;t=ts;va=vas;c=s}
    func deepcopy() -> Scalar {return Derivative(d.deepcopy(),t.deepcopy(),va,c)}
    func copy() -> Scalar {return Derivative(d,t,va,c)}
    func eval() -> Double {return 9999}
}
class Derivative2 : Vector2 {
    var d : Vector2
    var va : String
    var t : Vector2
    init(_ ds:Vector2,_ ts:Vector2,_ vas:String) {d=ds;t=ts;va=vas}
    func deepcopy() -> Vector2 {return Derivative2(d.deepcopy(),t.deepcopy(),va)}
    func copy() -> Vector2 {return Derivative2(d,t,va)}
    func eval() -> Vec2 {return Vec2(9999,9999)}
}
class Derivative3 : Vector3 {
    var d : Vector3
    var va : String
    var t : Vector3
    init(_ ds:Vector3,_ ts:Vector3,_ vas:String) {d=ds;t=ts;va=vas}
    func deepcopy() -> Vector3 {return Derivative3(d.deepcopy(),t.deepcopy(),va)}
    func copy() -> Vector3 {return Derivative3(d,t,va)}
    func eval() -> Vec3 {return Vec3(9999,9999,9999)}
}


class Integral : Scalar {
    var c : Int = 1
    var l : Scalar
    var u : Scalar
    var d : Scalar
    var va : String
    init(_ ds:Scalar,_ ls:Scalar,_ us:Scalar,_ vas:String) {d=ds;l=ls;u=us;va=vas}
    init(_ ds:Scalar,_ ls:Scalar,_ us:Scalar,_ vas:String,_ s:Int) {d=ds;l=ls;u=us;va=vas;c=s}
    func deepcopy() -> Scalar {return Integral(d.deepcopy(),l.deepcopy(),u.deepcopy(),va,c)}
    func copy() -> Scalar {return Integral(d,l,u,va,c)}
    func eval() -> Double {return 9999}
}
class Integral2 : Vector2 {
    var l : Scalar
    var u : Scalar
    var d : Vector2
    var va : String
    init(_ ds:Vector2,_ ls:Scalar,_ us:Scalar,_ vas:String) {d=ds;l=ls;u=us;va=vas}
    func deepcopy() -> Vector2 {return Integral2(d.deepcopy(),l.deepcopy(),u.deepcopy(),va)}
    func copy() -> Vector2 {return Integral2(d,l,u,va)}
    func eval() -> Vec2 {return Vec2(9999,9999)}
}
class Integral3 : Vector3 {
    var l : Scalar
    var u : Scalar
    var d : Vector3
    var va : String
    init(_ ds:Vector3,_ ls:Scalar,_ us:Scalar,_ vas:String) {d=ds;l=ls;u=us;va=vas}
    func deepcopy() -> Vector3 {return Integral3(d.deepcopy(),l.deepcopy(),u.deepcopy(),va)}
    func copy() -> Vector3 {return Integral3(d,l,u,va)}
    func eval() -> Vec3 {return Vec3(9999,9999,9999)}

}

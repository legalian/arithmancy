//
//  Technical.swift
//  Calcuplot
//
//  Created by Parker on 11/28/18.
//  Copyright © 2018 Parker. All rights reserved.
//

import Foundation



enum Scalar {
    case constant(Int)
    case special(String)
    case add([Scalar])
    case mult([Scalar])
    case max([Scalar])
    case min([Scalar])
    indirect case power(Scalar,Scalar)
    indirect case ln(Scalar)
    indirect case sin(Scalar)
    indirect case cos(Scalar)
    indirect case abs(Scalar)
    indirect case abs2(Vector2)
    indirect case abs3(Vector3)
    indirect case dot2(Vector2,Vector2)
    indirect case dot3(Vector3,Vector3)
    indirect case cross2(Vector2,Vector2)
    indirect case derivative(Scalar,Scalar,String)
    indirect case integral(Scalar,Scalar,Scalar,String)
}
enum Vector2 {
    case assemble(Scalar,Scalar)
    case add([Vector2])
    indirect case mult(Scalar,Vector2)
    indirect case derivative(Vector2,Scalar,String)
    indirect case integral(Vector2,Scalar,Scalar,String)
}
enum Vector3 {
    case assemble(Scalar,Scalar,Scalar)
    case add([Vector3])
    indirect case mult(Scalar,Vector3)
    indirect case cross3(Vector3,Vector3)
    indirect case derivative(Vector3,Scalar,String)
    indirect case integral(Vector3,Scalar,Scalar,String)
}
//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
func max_(_ a:Double,_ b:Double) -> Double {return max(a,b)}
func min_(_ a:Double,_ b:Double) -> Double {return max(a,b)}
func sin_(_ a:Double) -> Double {return sin(a)}
func cos_(_ a:Double) -> Double {return cos(a)}
func abs_(_ a:Double) -> Double {return abs(a)}

extension Scalar {
    func eval(_ va:[String:Double]) -> Double {
        switch self {
            case .constant(let c): return Double(c)
            case .special(let s): return va[s]!
            case .power(let b,let e): return pow(b.eval(va),e.eval(va))
            case .add(let a): return a.reduce(0){x,y in x+y.eval(va)}
            case .mult(let a): return a.reduce(1){x,y in x*y.eval(va)}
            case .max(let a): return a.dropFirst().reduce(a[0].eval(va)){x,y in max_(x,y.eval(va))}
            case .min(let a): return a.dropFirst().reduce(a[0].eval(va)){x,y in min_(x,y.eval(va))}
            case .ln(let x): return log(x.eval(va))
            case .sin(let x): return sin_(x.eval(va))
            case .cos(let x): return cos_(x.eval(va))
            case .abs(let x): return abs_(x.eval(va))
            case .abs2(let a):
                let g = a.eval(va);
                return sqrt(g.0*g.0+g.1*g.1)
            case .abs3(let a):
                let g = a.eval(va);
                return sqrt(g.0*g.0+g.1*g.1+g.2*g.2)
            case .dot2(let a,let b):
                let g = a.eval(va)
                let h = b.eval(va)
                return g.0*h.0+g.1*h.1
            case .dot3(let a,let b):
                let g = a.eval(va)
                let h = b.eval(va)
                return g.0*h.0+g.1*h.1+g.2*h.2
            case .cross2(let a,let b):
                let g = a.eval(va)
                let h = b.eval(va)
                return g.0*h.1-g.1*h.0
            case .derivative(let d,let a,let s):
                var ua = va;ua[s] = a.eval(va)
                return d.derivative(s).eval(ua)
            case .integral(let d,let l,let u,let s): return 9999
        }
    }
}
extension Vector2 {
    func eval(_ va:[String:Double]) -> (Double,Double) {
        switch self {
            case .assemble(let x,let y): return (x.eval(va),y.eval(va))
            case .add(let a): return a.reduce((0,0)){x,y in let g = y.eval(va);return (x.0+g.0,x.1+g.1)}
            case .mult(let a,let b): let g=b.eval(va);let h=a.eval(va);return (g.0*h,g.1*h)
            case .derivative(let d,let a,let s):
                var ua = va;ua[s] = a.eval(va)
                return d.derivative(s).eval(ua)
            case .integral(let d,let l,let u,let s): return (9999,9999)
        }
    }
}
extension Vector3 {
    func eval(_ va:[String:Double]) -> (Double,Double,Double) {
        switch self {
            case .assemble(let x,let y,let z): return (x.eval(va),y.eval(va),z.eval(va))
            case .add(let a): return a.reduce((0,0,0)){x,y in let g = y.eval(va);return (x.0+g.0,x.1+g.1,x.2+g.2)}
            case .mult(let a,let b): let g=b.eval(va);let h=a.eval(va);return (g.0*h,g.1*h,g.2*h)
            case .cross3(let a,let b):
                let (x1,y1,z1)=a.eval(va);
                let (x2,y2,z2)=b.eval(va);
                return (y1*z2-z1*y2,z1*x2-x1*z2,x1*y2-y1*x2)
            case .derivative(let d,let a,let s):
                var ua = va;ua[s] = a.eval(va)
                return d.derivative(s).eval(ua)
            case .integral(let d,let l,let u,let s): return (9999,9999,9999)
        }
    }
}
//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
extension Scalar {
    func latex() -> String {
        switch self {
            case .constant(let c): return String(c)
            case .special(let s): return s
            case .power(let b,let e):
                switch asrational(e) {
                    case .some(1,2):  return "\\sqrt{"+b.latex()+"}"
                    case .some(-1,1): return "\\frac{1}{"+b.latex()+"}"
                    case .some(-1,2): return "\\frac{1}{\\sqrt{"+b.latex()+"}}"
                    default: break;
                }
                switch b {
                    case .add,.mult,.power,.integral,.derivative,.dot2,.dot3,.cross2: return "("+b.latex()+")^{"+e.latex()+"}"
                    default: return b.latex()+"^{"+e.latex()+"}"
                }
            case .add(let a):
                if a.count==0 {return "0"}
                return a.dropFirst().reduce(a[0].latex()){j,g in
                    let y = coefsplit(g)
                    if y.1<0 {return j+"-"+((-y.1)*y.0).latex()}
                    return j+"+"+(y.1*y.0).latex()
                }
            case .mult(let a):
//                a.sort(by:{x,y in
//                    let a = x is Integral ?0:x is AddScalar ?2:x is MultScalar ?2:x is SpecialRef ?3:x is Constant ?4:1
//                    let b = y is Integral ?0:y is AddScalar ?2:y is MultScalar ?2:y is SpecialRef ?3:y is Constant ?4:1
//                    return a>=b
//                });
                var ayy:[Scalar]=[]
                var byy:[Scalar]=[]
                for g in a {
                    if case .power(let b,let e) = g {
                        if let dad = asrational(e), dad.0<0 {byy.append(.power(b,exactdivide(-dad.0,dad.1)))}
                        else {ayy.append(g)}
                    }
                }
                if byy.count==1 {
                    if ayy.count==1 {
                        return "\\frac{"+ayy[0].latex()+"}{"+byy[0].latex()+"}"
                    }
                    return "\\frac{"+Scalar.mult(ayy).latex()+"}{"+byy[0].latex()+"}"
                } else if byy.count>1 {
                    if ayy.count==1 {
                        return "\\frac{"+ayy[0].latex()+"}{"+Scalar.mult(byy).latex()+"}"
                    }
                    return "\\frac{"+Scalar.mult(ayy).latex()+"}{"+Scalar.mult(byy).latex()+"}"
                }
                var res = ""
                if a.count==0 {return "1"}
                for g in 0..<a.count {
                    switch a[g] {
                        case .integral:
                            if g == a.count-1 {res = res+a[g].latex()}
                            else {res = res+"("+a[g].latex()+")"}
                        case .add:res = res+"("+a[g].latex()+")"
                        case .mult:res = res+"("+a[g].latex()+")"
                        case .constant(-1):
                            if g == 0 {res = "-1"}
                            break
                        case .constant:
                            if g == 0 {res = res+a[g].latex()}
                            else {res = res+"("+a[g].latex()+")"}
                        default: res = res+a[g].latex()
                    }
                }
                return res
            case .max(let a):  return "max(" + a.dropFirst().reduce(a[0].latex()){x,y in x+","+y.latex()} + ")"
            case .min(let a):  return "min(" + a.dropFirst().reduce(a[0].latex()){x,y in x+","+y.latex()} + ")"
            case .ln(let x):   return "ln("+x.latex()+")"
            case .sin(let x):  return "sin("+x.latex()+")"
            case .cos(let x):  return "cos("+x.latex()+")"
            case .abs(let x):  return "|"+x.latex()+"|"
            case .abs2(let x): return "‖"+x.latex()+"‖"
            case .abs3(let x): return "‖"+x.latex()+"‖"
            case .dot2(let a,let b):   return a.latex()+"·"+b.latex()
            case .dot3(let a,let b):   return a.latex()+"·"+b.latex()
            case .cross2(let a,let b): return a.latex()+"×"+b.latex()
            case .derivative(let d,let a,let s):
                if case .special(s) = a {return "\\frac{\\partial}{\\partial"+s+"}("+d.latex()+")"}
                return "\\frac{\\partial}{\\partial"+s+"}("+d.latex()+",@"+a.latex()+")"
            case .integral(let d,let l,let u,let s): return "∫^{"+u.latex()+"}_{"+l.latex()+"}"+d.latex()+"d"+s
        }
    }
}
extension Vector2 {
    func latex() -> String {
        switch self {
            case .assemble(let x,let y): return "[^{"+x.latex()+"}_{"+y.latex()+"}]"
            case .mult(let a,.add(let b)): return a.latex()+"("+(Vector2.add(b)).latex()+")"
            case .mult(let a,let b): return a.latex()+b.latex()
            case .add(let a):
                if a.count==0 {return "0"}
                return a.dropFirst().reduce(a[0].latex()){j,g in
                    if case .mult(.constant(let cc),_) = g , cc<=0 {return j + g.latex()}
                    return j+"+"+g.latex()
                }
            case .derivative(let d,let a,let s):
                if case .special(s) = a {return "\\frac{\\partial}{\\partial"+s+"}("+d.latex()+")"}
                return "\\frac{\\partial}{\\partial"+s+"}("+d.latex()+",@"+a.latex()+")"
            case .integral(let d,let l,let u,let s): return "∫^{"+u.latex()+"}_{"+l.latex()+"}"+d.latex()+"d"+s
        }
    }
}
extension Vector3 {
    func latex() -> String {
        switch self {
            case .assemble(let x,let y,let z): return "[^{_{"+x.latex()+"}}_{^{"+y.latex()+"}_{"+z.latex()+"}}]"
            case .mult(let a,.add(let b)): return a.latex()+"("+(Vector3.add(b)).latex()+")"
            case .mult(let a,let b): return a.latex()+b.latex()
            case .add(let a):
                if a.count==0 {return "0"}
                return a.dropFirst().reduce(a[0].latex()){j,g in
                    if case .mult(.constant(let cc),_) = g , cc<=0 {return j + g.latex()}
                    return j+"+"+g.latex()
                }
            case .cross3(let a,let b): return a.latex()+"×"+b.latex()
            case .derivative(let d,let a,let s):
                if case .special(s) = a {return "\\frac{\\partial}{\\partial"+s+"}("+d.latex()+")"}
                return "\\frac{\\partial}{\\partial"+s+"}("+d.latex()+",@"+a.latex()+")"
            case .integral(let d,let l,let u,let s): return "∫^{"+u.latex()+"}_{"+l.latex()+"}"+d.latex()+"d"+s
        }
    }
}
//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
extension Vector2 {
    func separate() -> (Scalar,Scalar) {
        switch self {
            case .assemble(let x,let y): return (x,y)
            case .add(let a): let g = a.map{h in h.separate()};return (.add(g.map{h in h.0}),.add(g.map{h in h.1}))
            case .mult(let a,let b): let g=b.separate();return (a*g.0,a*g.1)
            case .derivative(let d,let a,let s): let g=d.separate();return (.derivative(g.0,a,s),.derivative(g.1,a,s))
            case .integral(let d,let l,let u,let s): let g=d.separate();return (.integral(g.0,l,u,s),.integral(g.1,l,u,s))
        }
    }
}
extension Vector3 {
    func separate() -> (Scalar,Scalar,Scalar) {
        switch self {
            case .assemble(let x,let y,let z): return (x,y,z)
            case .add(let a): let g = a.map{h in h.separate()};return (.add(g.map{h in h.0}),.add(g.map{h in h.1}),.add(g.map{h in h.2}))
            case .mult(let a,let b): let g=b.separate();return (a*g.0,a*g.1,a*g.2)
            case .cross3(let a,let b):
                let (x1,y1,z1)=a.separate();
                let (x2,y2,z2)=b.separate();
                return (y1*z2-z1*y2,z1*x2-x1*z2,x1*y2-y1*x2)
            case .derivative(let d,let a,let s): let g=d.separate();return (.derivative(g.0,a,s),.derivative(g.1,a,s),.derivative(g.2,a,s))
            case .integral(let d,let l,let u,let s): let g=d.separate();return (.integral(g.0,l,u,s),.integral(g.1,l,u,s),.integral(g.2,l,u,s))
        }
    }
}
//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
extension Scalar {
    func substitute(_ from:String,_ to:Scalar) -> Scalar {
        switch self {
            case .constant(let c): return .constant(c)
            case .special(let s): if s==from {return to}; return .special(s)
            case .power(let b,let e): return .power(b.substitute(from,to),e.substitute(from,to))
            case .add(let a): return .add(a.map{g in g.substitute(from,to)})
            case .mult(let a): return .mult(a.map{g in g.substitute(from,to)})
            case .max(let a): return .max(a.map{g in g.substitute(from,to)})
            case .min(let a): return .min(a.map{g in g.substitute(from,to)})
            case .ln(let x): return .ln(x.substitute(from,to))
            case .sin(let x): return .sin(x.substitute(from,to))
            case .cos(let x): return .cos(x.substitute(from,to))
            case .abs(let x): return .abs(x.substitute(from,to))
            case .abs2(let a): return .abs2(a.substitute(from,to))
            case .abs3(let a): return .abs3(a.substitute(from,to))
            case .dot2(let a,let b): return .dot2(a.substitute(from,to),b.substitute(from,to))
            case .dot3(let a,let b): return .dot3(a.substitute(from,to),b.substitute(from,to))
            case .cross2(let a,let b): return .cross2(a.substitute(from,to),b.substitute(from,to))
            case .derivative(let d,let a,let s):
                if s==from {return .derivative(d,a.substitute(from,to),s)}
                return .derivative(d.substitute(from,to),a.substitute(from,to),s)
            case .integral(let d,let l,let u,let s):
                if s==from {return .integral(d,l.substitute(from,to),u.substitute(from,to),s)}
                return .integral(d,l.substitute(from,to),u.substitute(from,to),s)
        }
    }
}
extension Vector2 {
    func substitute(_ from:String,_ to:Scalar) -> Vector2 {
        switch self {
            case .assemble(let x,let y): return .assemble(x.substitute(from,to),y.substitute(from,to))
            case .add(let a): return .add(a.map{g in g.substitute(from,to)})
            case .mult(let a,let b): return .mult(a.substitute(from,to),b.substitute(from,to))
            case .derivative(let d,let a,let s):
                if s==from {return .derivative(d,a.substitute(from,to),s)}
                return .derivative(d.substitute(from,to),a.substitute(from,to),s)
            case .integral(let d,let l,let u,let s):
                if s==from {return .integral(d,l.substitute(from,to),u.substitute(from,to),s)}
                return .integral(d,l.substitute(from,to),u.substitute(from,to),s)
        }
    }
}
extension Vector3 {
    func substitute(_ from:String,_ to:Scalar) -> Vector3 {
        switch self {
            case .assemble(let x,let y,let z): return .assemble(x.substitute(from,to),y.substitute(from,to),z.substitute(from,to))
            case .add(let a): return .add(a.map{g in g.substitute(from,to)})
            case .mult(let a,let b): return .mult(a.substitute(from,to),b.substitute(from,to))
            case .cross3(let a,let b): return .cross3(a.substitute(from,to),b.substitute(from,to))
            case .derivative(let d,let a,let s):
                if s==from {return .derivative(d,a.substitute(from,to),s)}
                return .derivative(d.substitute(from,to),a.substitute(from,to),s)
            case .integral(let d,let l,let u,let s):
                if s==from {return .integral(d,l.substitute(from,to),u.substitute(from,to),s)}
                return .integral(d,l.substitute(from,to),u.substitute(from,to),s)
        }
    }
}
//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
extension Scalar {
    func derivative(_ va:String) -> Scalar {
        switch self {
            case .constant: return .constant(0)
            case .power(let b,let e): return pow(b,e + .constant(-1))*b.derivative(va) + pow(b,e) * .ln(b)*e.derivative(va)
            case .add(let a): return a.reduce(.constant(0)){x,y in x+y.derivative(va)}
            case .mult(let a):
                var acc : Scalar = .constant(0)
                for g in 0..<a.count {
                    var bcc = a[g].derivative(va)
                    for d in 0..<a.count {
                        if g != d {bcc = bcc * a[d]}
                    }
                    acc = acc + bcc
                }
                return acc
            case .max: return shallowSimplify(self).derivative(va)
            case .min: return shallowSimplify(self).derivative(va)
            case .ln(let x): return x.derivative(va)/x
            case .sin(let x): return .cos(x)*x.derivative(va)
            case .cos(let x): return .sin(x)*x.derivative(va)
            case .special(let s): if s==va {return .constant(1)}; return .constant(0)
            case .abs(let x): return x.derivative(va) * .abs(x)/x
            case .abs2(let a): return .dot2(a,a.derivative(va)) / .abs2(a)
            case .abs3(let a): return .dot3(a,a.derivative(va)) / .abs3(a)
            case .dot2(let a,let b): return .dot2(a,b.derivative(va)) + .dot2(a.derivative(va),b)
            case .dot3(let a,let b): return .dot3(a,b.derivative(va)) + .dot3(a.derivative(va),b)
            case .cross2(let a,let b): return .cross2(a,b.derivative(va)) - .cross2(a.derivative(va),b)
            case .derivative(let d,let a,let s): return d.derivative(s).substitute(s,a).derivative(va)
            case .integral(let d,let l,let u,let s):
                if va==s {return d.substitute(s,u)*u.derivative(va)-d.substitute(s,l)*l.derivative(va)}
                return d.substitute(s,u)*u.derivative(va)-d.substitute(s,l)*l.derivative(va) + .integral(d.derivative(va),l,u,s)
        }
    }
}
extension Vector2 {
    func derivative(_ va:String) -> Vector2 {
        switch self {
            case .assemble(let x,let y): return .assemble(x.derivative(va),y.derivative(va))
            case .add(let a): return .add(a.map{g in g.derivative(va)})
            case .mult(let a,let b): return .add([.mult(a.derivative(va),b),.mult(a,b.derivative(va))])
            case .derivative(let d,let a,let s): return d.derivative(s).substitute(s,a).derivative(va)
            case .integral(let d,let l,let u,let s):
                if va==s {return Vector2.mult(u.derivative(va),d.substitute(s,u)) - Vector2.mult(l.derivative(va),d.substitute(s,l))}
                return Vector2.mult(u.derivative(va),d.substitute(s,u)) - Vector2.mult(l.derivative(va),d.substitute(s,l)) + .integral(d.derivative(va),l,u,s)
        }
    }
}
extension Vector3 {
    func derivative(_ va:String) -> Vector3 {
        switch self {
            case .assemble(let x,let y,let z): return .assemble(x.derivative(va),y.derivative(va),z.derivative(va))
            case .add(let a): return .add(a.map{g in g.derivative(va)})
            case .mult(let a,let b): return .add([.mult(a.derivative(va),b),.mult(a,b.derivative(va))])
            case .cross3(let a,let b): return .cross3(a,b.derivative(va)) - .cross3(a.derivative(va),b)
            case .derivative(let d,let a,let s): return d.derivative(s).substitute(s,a).derivative(va)
            case .integral(let d,let l,let u,let s):
                if va==s {return Vector3.mult(u.derivative(va),d.substitute(s,u)) - Vector3.mult(l.derivative(va),d.substitute(s,l))}
                return Vector3.mult(u.derivative(va),d.substitute(s,u)) - Vector3.mult(l.derivative(va),d.substitute(s,l)) + .integral(d.derivative(va),l,u,s)
        }
    }
}

func trigolook(_ a:Int) -> Scalar {
    if a>=24 || a<0 {return trigolook(a%%24)}
    if a>=12 {return trigolook(a-12) * -1}
    if a>6   {return trigolook(6-a) * -1}
    switch (a) {
        case 0: return .constant(1)
        case 1: return (pow(.constant(6),exactdivide(1,2))+pow(.constant(2),exactdivide(1,2)))/4
        case 2: return pow(.constant(3),exactdivide(1,2))/2
        case 3: return pow(.constant(2),exactdivide(-1,2))
        case 4: return exactdivide(1,2)
        case 5: return (pow(.constant(6),exactdivide(1,2))-pow(.constant(2),exactdivide(1,2)))/4
        default: return .constant(0)
    }
}
func simpexp(_ b:Int,_ r:Int) -> (Int,Int,Int) {
    var out = b<0 ? -1:1
    var fb = abs(b)
    var ie = r
    var g=2;
    while pow(g,r)<=fb {
        if fb%pow(g,r) == 0 {
            fb = fb/pow(g,r)
            out *= g
            g=1
        }
        g=g+1
    }
    g=2;
    while g*g<=ie {
        if ie%g==0 {
            var j=2;
            while pow(j,g)<=fb {
                if pow(j,g)==fb {fb=j;ie=ie/g;j=1;g=1}
                j=j+1
            }
        }
        g=g+1
    }
    return (out,fb,ie)
}
func shallowSimplify(_ fod:Scalar) -> Scalar {
    switch fod {
        case .power(let b,.add(let e)): return .mult(e.map{j in shallowSimplify(.power(b,j))})
        case .power(.power(let vb,let ve),let e):return shallowSimplify(.power(vb,ve*e))
        case .power(.mult(let v),let e):return .mult(v.map{h in shallowSimplify(.power(h,e))})
        case .power(.constant(let b),.constant(let e)):
            if e>=0 {return .constant(pow(b,e))}
            if e%2==1 && b<0 {return -(.power(.constant(pow(b,-e)),.constant(-1)))}
            return .power(.constant(pow(b,-e)),.constant(-1))
        case .power(.constant(let b),let e):
            if let (en,ed) = asrational(e) {
                let (kc,kb,kr) = simpexp(b,ed)
                if kb==1 {return .constant(pow(kc,en))}
                if kc==1 {return root(kb,kr)}
                return .constant(pow(kc,en)) * root(kb,kr)
            }
        case .power(.special("e"),.ln(let v)): return v
        case .power(_,.constant(0)): return .constant(1)
        case .power(let b,.constant(1)): return b
        case .power(.constant(0),_): return .constant(0)
        case .power(.constant(1),_): return .constant(1)
        case .add(let a):
            var b : [Scalar] = []
            var recur: (([Scalar]) -> Void)!
            recur = {f in for n in f {
                if case .add(let a) = n {recur(a)}
                else {b.append(n)}
            }}
            recur(a)
            b = doubleRemap(b,{x,y in
                let (dx,xc) = coefsplit(x)
                let (dy,yc) = coefsplit(y)
                if dx==dy {return (dx * .constant(xc+yc),nil,nil)}
                return (x,y,nil)
            })
            if b.count==0 {return .constant(0)}
            if b.count==1 {return b[0]}
            return .add(b)
        case .mult(let a):
            var conse : [(Scalar,Int,Int)] = []
            var conco : [(Int,Int)] = []
            var expba : [Scalar] = []
            var b : [Scalar] = []
            var poskeep = 1
            var negkeep = 1
            var recur: (([Scalar]) -> Void)!
            recur = {f in for n in f {
                if case .mult(let a) = n {recur(a)}
                let (mb,me) = aspower(n)
                if let (nu,de) = asrational(me) {
                    if let a = asint(mb) {
                        if (nu<0) {conco.append((pow(a,-nu),-de))}
                        else {conco.append((pow(a,nu),de))}
                    } else {
                        conse.append((mb,nu,de))
                    }
                } else {expba.append(me * .ln(mb))}
            }}
            recur(a)
            for y in doubleRemap(doubleRemap(conco,{a,b in
                let gc = gcf(a.0,b.0)
                if gc==1 {return (a,b,nil)}
                let gcc = gcf(a.1+b.1,a.1*b.1)
                var a=a,b=b
                a.0/=gc ; b.0/=gc
                if a.1+b.1>0 {return (a.0==1 ?nil:a,b.0==1 ?nil:b,(pow(gc,(a.1+b.1)/gcc),(a.1*b.1)/gcc))}
                if a.1+b.1<0 {return (a.0==1 ?nil:a,b.0==1 ?nil:b,(pow(gc,-(a.1+b.1)/gcc),-(a.1*b.1)/gcc))}
                return (a.0==1 ?nil:a,b.0==1 ?nil:b,nil)
            }),{a,b in
                if a.1 ==  1 {poskeep*=a.0;return (nil,b,nil)}
                if b.1 ==  1 {poskeep*=b.0;return (a,nil,nil)}
                if a.1 ==  0 {return (nil,b,nil)}
                if b.1 ==  0 {return (a,nil,nil)}
                if a.1 == -1 {negkeep*=a.0;return (nil,b,nil)}
                if b.1 == -1 {negkeep*=b.0;return (a,nil,nil)}
                if a.1<0 && b.1<0 {
                    let gc = gcf(a.1,b.1)
                    let (kc,kb,kr) = simpexp(pow(a.0,-b.1/gc)+pow(b.0,-a.1/gc),a.1*b.1/gc)
                    negkeep*=kc;return ((kb,kr),nil,nil)
                }
                if a.1>0 && b.1>0 {
                    let gc = gcf(a.1,b.1)
                    let (kc,kb,kr) = simpexp(pow(a.0,b.1/gc)+pow(b.0,a.1/gc),a.1*b.1/gc)
                    poskeep*=kc;return ((kb,kr),nil,nil)
                }
                return (a,b,nil)
            }) {
                if y.0 != 1 {
                    b.append(root(y.0,y.1))
                }
            }
            for y in doubleRemap(conse,{a,b in
                if a.0 == b.0 {
                    let gc = gcf(a.1*b.2+b.1*a.2,a.2*b.2)
                    return ((a.0,(a.1*b.2+b.1*a.2)/gc,a.2*b.2/gc),nil,nil)
                }
                return (a,b,nil)
            }) {
                if y.1 != 0 {
                    b.append(pow(y.0,exactdivide(y.1,y.2)))
                }
            }
            for y in asaddchain(shallowSimplify(.add(expba))) {
                b.append(.power(.special("e"),y))
            }
            if poskeep==0 {return .constant(0)}
            if poskeep != 1 {b.append(.constant(poskeep))}
            if negkeep != 1 {b.append(reciprocal(negkeep))}
            if b.count==0 {return .constant(1)}
            if b.count==1 {return b[0]}
            return .mult(b)
        case .ln(.constant(1)): return .constant(0)
        case .ln(.special("e")): return .constant(1)
        case .ln(.power(.special("e"),let e)): return e
        case .sin(let x):
            let (v,n,d) = rationalcoefsplit(x)
            if v == .special("π") && d<12 && 12%d==0  {return trigolook(6-n*(12/d))}
        case .cos(let x):
            let (v,n,d) = rationalcoefsplit(x)
            if v == .special("π") && d<12 && 12%d==0  {return trigolook(n*(12/d))}
        case .abs(.abs(let x)):  return .abs(x)
        case .abs(.abs2(let x)): return .abs2(x)
        case .abs(.abs3(let x)): return .abs3(x)
        default:break;
    }
    return fod;
}


func narrowSimplify(_ fod:Scalar) -> Scalar {
    switch fod {
        case .power(let b,let e): return shallowSimplify(.power(narrowSimplify(b),broadSimplify(e)))
        case .mult(let a): return shallowSimplify(.mult(a.map{j in narrowSimplify(j)}))
        case .add:
            let fo = broadSimplify(fod)
            if case .add(let a) = fo {
                let gc = gcf(a);
                return gc*shallowSimplify(.add(a.map{h in narrowSimplify(h*pow(gc,-1))}))
            }
            return fo
        case .abs(let a):
            return shallowSimplify(.mult(asmultchain(narrowSimplify(a)).map{j in .abs(j)}))
        default:break
    }
    return fod
}
func broadSimplify(_ fod:Scalar) -> Scalar {
    switch fod {
        case .power:
            return shallowSimplify(.mult(asmultchain(narrowSimplify(fod)).map{g in
            if case .power(let b,let e) = g {
                if let e = asint(e) {
                    if e >  1 {return distribute([Scalar](repeating:b,count:e))}
                    if e < -1 {return .power(distribute([Scalar](repeating:b,count:-e)),.constant(-1))}
                } else if let (en,ed) = asrational(e) {
                    if en >  1 {return .power(distribute([Scalar](repeating:b,count:en)),reciprocal(ed))}
                    if en < -1 {return .power(distribute([Scalar](repeating:b,count:-en)),-reciprocal(ed))}
                }
                return g
            }
            return g
            }))
        case .mult:
            let fo = narrowSimplify(fod)
            if case .mult(let a) = fo {return distribute(a)}
            return fo
        case .add(let a): return shallowSimplify(.add(a.map{j in broadSimplify(j)}))
        default:break
    }
    return fod
}

func distribute(_ a:[Scalar]) -> Scalar {
    var accu:[Scalar]=[.constant(1)]
    for bd in a {
        if case .add(let b) = bd {
            var bccu:[Scalar]=[]
            for q in accu {for y in b {bccu.append(q*y)}}
            accu=bccu
        } else {
            for q in 0..<accu.count {accu[q] = accu[q]*bd}
        }
    }
    return shallowSimplify(.add(accu))
}

//
//func dissolveSimplify(_ fod:Scalar) -> Scalar {
//    switch fod {
//        case .abs(.sin(let x)):
//        default:break
//    }
//    return fod
//}


//sin^2 + cos^2 = 1
//sin = sqrt(1-cos^2)


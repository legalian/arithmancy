//
//  Graphing.swift
//  Calcuplot
//
//  Created by Parker on 1/5/19.
//  Copyright © 2019 Parker. All rights reserved.
//

import Foundation
import SceneKit

func cross(_ a:SCNVector3,_ b:SCNVector3) -> SCNVector3 {return SCNVector3(a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x)}
func -(_ a:SCNVector3,_ b:SCNVector3) -> SCNVector3 {return SCNVector3(a.x-b.x,a.y-b.y,a.z-b.z)}
func +(_ a:SCNVector3,_ b:SCNVector3) -> SCNVector3 {return SCNVector3(a.x+b.x,a.y+b.y,a.z+b.z)}
func *(_ a:SCNVector3,_ b:Float) -> SCNVector3 {return SCNVector3(a.x*b,a.y*b,a.z*b)}
func /(_ a:SCNVector3,_ b:Float) -> SCNVector3 {return a*(1/b)}
func magnitude(_ a:SCNVector3) -> Float {return sqrt(a.x*a.x+a.y*a.y+a.z*a.z)}


//func encaps(_ points:inout [SCNVector3],_ r:Float,_ a:SCNVector3,_ b:SCNVector3,_ c:SCNVector3) {
//    let udv = SCNVector3(a.y-b.y,b.x-a.x,0)
//    let dv = udv/magnitude(udv)
//    points.append(b+dv*r)
//    points.append(b-dv*r)
//}

func encircle(_ points:inout [SCNVector3],_ s:Int,_ r:Float,_ b:SCNVector3,_ ba:SCNVector3,_ bc:SCNVector3,_ ac:SCNVector3) {
    let uup = cross(ba,bc)
    let uou = cross(ac,uup)
    let up = uup/magnitude(uup)
    let ou = uou/magnitude(uou)
    let dt = 2*3.1415926/Float(s)
    for t in 0..<s {
        points.append(b+up*r*sin(dt*Float(t))+ou*r*cos(dt*Float(t)))
    }
}

func addpanel(_ inds:inout [UInt16],_ a:Int,_ b:Int,_ c:Int,_ d:Int) {
    inds.append(UInt16(a))
    inds.append(UInt16(b))
    inds.append(UInt16(c))
    inds.append(UInt16(b))
    inds.append(UInt16(c))
    inds.append(UInt16(d))
}


struct Vec2 {
    var x: Float
    var y: Float
}
struct SamVec2 {
    var x: Float
    var y: Float
    var val: Float
    init(_ xy:Vec2,_ v:Float) {x=xy.x;y=xy.y;val=v}
    init(_ xx:Int,_ yy:Int,_ v:Float) {x=Float(xx);y=Float(yy);val=v}
}
class VertSet {
    var verts:[Vec2]=[]
    var inds:[Int]=[]
    func crosscompare(_ a:SamVec2,_ b:SamVec2,_ i:inout MarchSegment) {
//        if (a.val>0) == (b.val>0) {return}
        guard case .uncap(let ic) = i else {return}
        guard ic == -1 else {inds.append(ic);return}
        let c = a.val/(a.val-b.val)
        addvert(Vec2(x:c*(b.x-a.x)+a.x,y:c*(b.y-a.y)+a.y))
        i = .uncap(verts.count-1)
    }
    func addvert(_ a:Vec2) {
        verts.append(a)
    }
}

enum MarchSegment {
    case uncap(Int)
    indirect case split(MarchSegment,MarchSegment)
    func split() -> (MarchSegment,MarchSegment) {
        switch self {
            case .split(let a,let b): return (a,b)
            case .uncap: return (.uncap(-1),.uncap(-1))
        }
    }
    func split(_ n:Int) -> [MarchSegment] {
        switch self {
            case .split(let a,let b): return a.split(n-1)+b.split(n-1)
            case .uncap:
                if n==0 {return [self]}
                return [MarchSegment](repeating: .uncap(-1), count:(1<<n))
        }
    }
}


enum MarchSquare {
    case uncap
    indirect case vert(MarchSquare,MarchSquare,Int,Int)
    indirect case hori(MarchSquare,MarchSquare,Int,Int)
    indirect case ul(MarchTriangle,MarchTriangle,MarchTriangle,MarchTriangle,Int,Int)
    indirect case ur(MarchTriangle,MarchTriangle,MarchTriangle,MarchTriangle,Int,Int)
    indirect case ll(MarchTriangle,MarchTriangle,MarchTriangle,MarchTriangle,Int,Int)
    indirect case lr(MarchTriangle,MarchTriangle,MarchTriangle,MarchTriangle,Int,Int)
    indirect case alt(MarchSquare,MarchTriangle,MarchTriangle,MarchTriangle,MarchTriangle,Int,Int,Int,Int)
    func render(_ points:VertSet,_ iul:SamVec2,_ iur:SamVec2,_ ill:SamVec2,_ ilr:SamVec2,_ ia:inout MarchSegment,_ ib:inout MarchSegment,_ ic:inout MarchSegment,_ id:inout MarchSegment,
        _ f:(Vec2) -> Float) {
        switch self {
            case .uncap:
                switch ((iul.val>0)==(ill.val>0),(iur.val>0)==(ill.val>0),(ilr.val>0)==(ill.val>0)) {
                    case (true,true,true): return
                    case (true,true,false):   points.crosscompare(ill,ilr,&ic);points.crosscompare(iur,ilr,&ib);
                    case (true,false,true):   points.crosscompare(iur,ilr,&ib);points.crosscompare(iul,iur,&ia);
                    case (true,false,false):  points.crosscompare(iul,iur,&ia);points.crosscompare(ill,ilr,&ic);//vert
                    case (false,true,true):   points.crosscompare(iul,iur,&ia);points.crosscompare(iul,ill,&id);
                    case (false,false,true):  points.crosscompare(iul,ill,&id);points.crosscompare(iur,ilr,&ib);//horiz
                    case (false,false,false): points.crosscompare(iul,ill,&id);points.crosscompare(ill,ilr,&ic);
                    case (false,true,false):
                        points.crosscompare(iul,iur,&ia);points.crosscompare(iul,ill,&id);
                        points.crosscompare(ill,ilr,&ic);points.crosscompare(iur,ilr,&ib);
                }
            case .vert(let l,let r,let a,let c):
                let avert = SamVec2(points.verts[a],f(points.verts[a])); var ma = ia.split()
                let cvert = SamVec2(points.verts[c],f(points.verts[c])); var mc = ic.split()
                var mh = MarchSegment.uncap(-1)
                l.render(points,iul,avert,ill,cvert,&ma.0,&mh,&mc.1,&id,f)
                r.render(points,avert,iur,cvert,ilr,&ma.1,&ib,&mc.0,&mh,f)
                ia = .split(ma.0,ma.1); ic = .split(mc.0,mc.1)
            
            case .hori(let u,let l,let d,let b):
                let dvert = SamVec2(points.verts[d],f(points.verts[d])); var md = id.split()
                let bvert = SamVec2(points.verts[b],f(points.verts[b])); var mb = ib.split()
                var mh = MarchSegment.uncap(-1)
                u.render(points,iul,iur,dvert,bvert,&ia,&mb.0,&mh,&md.1,f)
                l.render(points,dvert,bvert,ill,ilr,&mh,&mb.1,&ic,&md.0,f)
                ib = .split(mb.0,mb.1); id = .split(md.0,md.1)
            
            case .ul(let spt,let cent,let bwing,let cwing,let a,let d):
                let avert = SamVec2(points.verts[a],f(points.verts[a])); var ma = ia.split()
                let dvert = SamVec2(points.verts[d],f(points.verts[d])); var md = id.split()
                var mh = MarchSegment.uncap(-1),mb = MarchSegment.uncap(-1),mc = MarchSegment.uncap(-1)
                spt.render(points,iul,avert,dvert,&ma.0,&mh,&md.1,f)
                cent.render(points,dvert,avert,ilr,&mh,&mb,&mc,f)
                bwing.render(points,avert,iur,ilr,&ma.1,&ib,&mb,f)
                cwing.render(points,dvert,ilr,ill,&mc,&ic,&md.0,f)
            
            case .ur(let spt,let cent,let cwing,let dwing,let b,let a):
                let bvert = SamVec2(points.verts[b],f(points.verts[b])); var mb = ib.split()
                let avert = SamVec2(points.verts[a],f(points.verts[a])); var ma = ia.split()
                var mh = MarchSegment.uncap(-1),mc = MarchSegment.uncap(-1),md = MarchSegment.uncap(-1)
                spt.render(points,iur,bvert,avert,&mb.0,&mh,&ma.1,f)
                cent.render(points,avert,bvert,ill,&mh,&mc,&md,f)
                cwing.render(points,bvert,ilr,ill,&mb.1,&ic,&mc,f)
                dwing.render(points,avert,ill,iul,&md,&id,&ma.0,f)

            case .lr(let spt,let cent,let dwing,let awing,let c,let b):
                let cvert = SamVec2(points.verts[c],f(points.verts[c])); var mc = ic.split()
                let bvert = SamVec2(points.verts[b],f(points.verts[b])); var mb = ib.split()
                var mh = MarchSegment.uncap(-1),md = MarchSegment.uncap(-1),ma = MarchSegment.uncap(-1)
                spt.render(points,ilr,cvert,bvert,&mc.0,&mh,&mb.1,f)
                cent.render(points,bvert,cvert,iul,&mh,&md,&ma,f)
                dwing.render(points,cvert,ill,iul,&mc.1,&id,&md,f)
                awing.render(points,bvert,iul,iur,&ma,&ia,&mb.0,f)

            case .ll(let spt,let cent,let awing,let bwing,let d,let c):
                let dvert = SamVec2(points.verts[d],f(points.verts[d])); var md = id.split()
                let cvert = SamVec2(points.verts[c],f(points.verts[c])); var mc = ic.split()
                var mh = MarchSegment.uncap(-1),ma = MarchSegment.uncap(-1),mb = MarchSegment.uncap(-1)
                spt.render(points,ill,dvert,cvert,&md.0,&mh,&mc.1,f)
                cent.render(points,cvert,dvert,iur,&mh,&ma,&mb,f)
                awing.render(points,dvert,iul,iur,&md.1,&ia,&ma,f)
                bwing.render(points,cvert,iur,ilr,&mb,&ib,&mc.0,f)
            
            case .alt(let sq,let ul,let ur,let ll,let lr,let a,let b,let c,let d):
                let avert = SamVec2(points.verts[a],f(points.verts[a]))
                let bvert = SamVec2(points.verts[b],f(points.verts[b]))
                let cvert = SamVec2(points.verts[c],f(points.verts[c]))
                let dvert = SamVec2(points.verts[d],f(points.verts[d]))
                var mul = MarchSegment.uncap(-1),mur = MarchSegment.uncap(-1),mll = MarchSegment.uncap(-1),mlr = MarchSegment.uncap(-1)
                var asp = ia.split(),bsp = ib.split(),csp = ic.split(),dsp = id.split()
                sq.render(points,avert,bvert,dvert,cvert,&mur,&mlr,&mll,&mul,f)
                ul.render(points,iul,avert,dvert,&asp.0, &mul, &dsp.1, f)
                ur.render(points,iur,bvert,avert,&bsp.0, &mur, &asp.1, f)
                lr.render(points,ilr,cvert,bvert,&csp.0, &mlr, &bsp.1, f)
                ll.render(points,ill,dvert,cvert,&dsp.0, &mll, &csp.1, f)
                ia = .split(asp.0,asp.1);ib = .split(bsp.0,bsp.1);ic = .split(csp.0,csp.1);id = .split(dsp.0,dsp.1)
        }
    }
}
enum MarchTriangle {
    case uncap
    indirect case vx(MarchSquare,MarchTriangle,Int,Int)
    indirect case vy(MarchSquare,MarchTriangle,Int,Int)
    indirect case vz(MarchSquare,MarchTriangle,Int,Int)
    func render(_ points:VertSet,_ ix:SamVec2,_ iy:SamVec2,_ iz:SamVec2,_ ia: inout MarchSegment,_ ib: inout MarchSegment,_ ic: inout MarchSegment,
        _ f:(Vec2) -> Float) {
        switch self {
            case .uncap:
            switch ((iy.val>0)==(iz.val>0),(ix.val>0)==(iz.val>0)) {
                case (true,true): return
                case (true,false):  points.crosscompare(ix,iy,&ia);points.crosscompare(iy,iz,&ib);
                case (false,true):  points.crosscompare(ix,iy,&ia);points.crosscompare(iz,ix,&ic);
                case (false,false): points.crosscompare(iy,iz,&ib);points.crosscompare(iz,ix,&ic);
            }
            case .vx(let body,let head,let a,let c):
                let avert = SamVec2(points.verts[a],f(points.verts[a])); var ma = ia.split()
                let cvert = SamVec2(points.verts[c],f(points.verts[c])); var mc = ic.split()
                var mh = MarchSegment.uncap(-1)
                head.render(points,ix,avert,cvert,&ma.0,&mh,&mc.1,f)
                body.render(points,avert,iy,cvert,iz,&ma.1,&ib,&mc.0,&mh,f)
            case .vy(let body,let head,let b,let a):
                let bvert = SamVec2(points.verts[b],f(points.verts[b])); var mb = ib.split()
                let avert = SamVec2(points.verts[a],f(points.verts[a])); var ma = ia.split()
                var mh = MarchSegment.uncap(-1)
                head.render(points,iy,bvert,avert,&mb.0,&mh,&ma.1,f)
                body.render(points,bvert,iz,avert,ix,&mb.1,&ic,&ma.0,&mh,f)
            case .vz(let body,let head,let c,let b):
                let cvert = SamVec2(points.verts[c],f(points.verts[c])); var mc = ic.split()
                let bvert = SamVec2(points.verts[b],f(points.verts[b])); var mb = ib.split()
                var mh = MarchSegment.uncap(-1)
                head.render(points,iz,cvert,bvert,&mc.0,&mh,&mc.1,f)
                body.render(points,cvert,ix,bvert,iy,&mc.1,&ia,&mb.0,&mh,f)
        }
    }
}
enum QuadTree {
    case empty(Int,Int,Int)
    case cap(MarchSquare,Int,Int)
    indirect case branch(QuadTree,QuadTree,QuadTree,QuadTree)
    func render(_ points:VertSet,_ dt:inout DataType2D,_ ia:inout MarchSegment,_ ib:inout MarchSegment,_ ic:inout MarchSegment,_ id:inout MarchSegment) {
        switch (self,dt) {
            case (.empty(let depth,let xs,let ys),.full):
                var cof = ic.split(depth)
                var dstart = id.split(depth)
                var bend = ib.split(depth)
                for x in xs..<(xs+(1<<depth)) {
                    var aof = x == (xs+(1<<depth)-1) ? [MarchSegment](repeating: .uncap(-1), count:(1<<depth))
                    var dof = MarchSegment.uncap(-1)
                    for y in ys..<(ys+(1<<depth)) {
                        var bof = MarchSegment.uncap(-1)
                        MarchSquare.uncap.render(points,
                            SamVec2(x,y+1,dt.sample(x,y+1)),SamVec2(x+1,y+1,dt.sample(x+1,y+1)),
                            SamVec2(x,y,dt.sample(x,y))    ,SamVec2(x+1,y,dt.sample(x+1,y)),
                            &aof[y],&bof,&cof[y],&dof,dt.sample)
                        dof=bof
                    }
                    cof=aof
                }
            
            case (.cap(let ms,let x,let y),_): ms.render(points,
                SamVec2(x,y+1,dt.sample(x,y+1)),SamVec2(x+1,y+1,dt.sample(x+1,y+1)),
                SamVec2(x,y,dt.sample(x,y))    ,SamVec2(x+1,y,dt.sample(x+1,y)),
                &ia,&ib,&ic,&id,dt.sample)
            
        }
    }
    mutating func mark(_ dt:inout DataType2D) {
        switch (self,dt) {
            
        }
    }
}
class Markup2D {
    var qt: QuadTree
    var xlines: [Float] = []
    var ylines: [Float] = []
    var sd: Int
    init(_ subdiv:Int) {qt = .empty(subdiv,0,0);sd=subdiv}
    func mark(_ dt:inout DataType2D) {
        switch dt {
            case .xconst(let x): xlines.append(x);
            case .yconst(let y): ylines.append(y);
            default: qt.mark(&dt)
        }
    }
    func render(_ points:VertSet,_ dt:inout DataType2D) {
        switch dt {
            case .xconst(let x): points.addvert(Vec2(x:x,y:0));points.addvert(Vec2(x:x,y:1+Float(1<<sd)))
            case .yconst(let y): points.addvert(Vec2(x:0,y:y));points.addvert(Vec2(x:1+Float(1<<sd),y:y))
            default: qt.render(points,&dt)
        }
    }
}
enum DataType2D {
    case full([[Float]])
    case funcx([Float])
    case funcy([Float])
    case funcxy([Float],[Float])
    case sumxy([Float],[Float])
    
    case xconst(Float)
    case yconst(Float)
    func sample(_ x:Int,_ y:Int) -> Float {
        
    }
    func sample(_ xy:Vec2) -> Float {
    
    }
}
//enum GraphType3D {
//    case full([[[Float]]])
//    case sumxyz([Float],[Float],[Float])
//    case funcx(GraphType2D)
//    case funcy(GraphType2D)
//    case funcz(GraphType2D)
//    case funcxy(GraphType2D,GraphType2D)
//    case funcyz(GraphType2D,GraphType2D)
//    case funczx(GraphType2D,GraphType2D)
//    case funcxyz(GraphType2D,GraphType2D,GraphType2D)
//    case xplus([Float],GraphType2D)
//    case yplus([Float],GraphType2D)
//    case zplus([Float],GraphType2D)
//    case xinvariant(GraphType2D)
//    case yinvariant(GraphType2D)
//    case zinvariant(GraphType2D)
//    case xconst(Float)
//    case yconst(Float)
//    case zconst(Float)
//}




class GraphingView: UIViewController {
    @IBOutlet var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    var graphnode: SCNNode? = nil
    
    weak var equations : EquationListController? = nil
    
    func shouldAutorotate() -> Bool {
        return true
    }

    func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        scnView = self.view as! SCNView
        scnScene = SCNScene()
        scnView.scene = scnScene
        
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
        scnScene.rootNode.addChildNode(cameraNode)
        
        
        
        scnView.allowsCameraControl = true
        scnView.allowsCameraControl = false
        // 3
        scnView.autoenablesDefaultLighting = true
//        addCustomGeometry()
        updateGraphs()
    }
    func updateGraphs() {
        add3DGeometry()
    }
    
    
    
    
    func addCustomGeometry() {
        let vertices: [SCNVector3] = [
            SCNVector3(   0, 1,   0),
            SCNVector3(-0.5, 0, 0.5),
            SCNVector3( 0.5, 0, 0.5),
            SCNVector3( 0.5, 0,-0.5),
            SCNVector3(-0.5, 0,-0.5),
            SCNVector3(   0,-1,   0),
        ]
        let indices: [UInt16] = [
            0, 1, 2,
            2, 3, 0,
            3, 4, 0,
            4, 1, 0,
            1, 5, 2,
            2, 5, 3,
            3, 5, 4,
            4, 5, 1
        ]
        let node = SCNNode(geometry:SCNGeometry(sources:[SCNGeometrySource(vertices: vertices)],elements:[SCNGeometryElement(indices: indices, primitiveType: .triangles)]))
//        node.scale = SCNVector3(1,1,1);
//        node.position = SCNVector3(0,0,0);
        scnView.scene?.rootNode.addChildNode(node)
//        let rotateAction = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: .pi, z: 0, duration: 5))
//        node.runAction(rotateAction)
    }
    func add3DGeometry() {
        var samples: [SCNVector3] = []
        var vertices: [SCNVector3] = []
        var indices: [UInt16] = []
        guard let equations = equations else {return}
        guard equations.equations.count>0 else {return}
        guard case .scalar(let eq1) = equations.equations[0].parsedfunc else {return}
        guard (scnScene != nil) else {return}
        for x in 0...10 {
            samples.append(SCNVector3(Double(x-5)/3.0,eq1.eval(["x":Double(x-5)/3.0]),0))
        }
        
        let s = 6
        let r : Float = 0.05
        if samples.count<3 {return}
        encircle(&vertices,s,r,samples[0],
            samples[1]-samples[0],
            samples[1]-samples[2],
            samples[0]-samples[1])
        for t in 1..<samples.count-1 {encircle(&vertices,s,r,samples[t],samples[t]-samples[t-1],samples[t]-samples[t+1],samples[t-1]-samples[t+1])}
        encircle(&vertices,s,r,samples[samples.count-1],
            samples[samples.count-2]-samples[samples.count-3],
            samples[samples.count-2]-samples[samples.count-1],
            samples[samples.count-2]-samples[samples.count-1])
        for t in 0..<samples.count-1 {for g in 0..<s {addpanel(&indices,t*s+g,t*s+(g+1)%s,t*s+s+g,t*s+s+(g+1)%s)}}
        
        if let node=graphnode {node.removeFromParentNode()}
        graphnode = SCNNode(geometry:SCNGeometry(sources:[SCNGeometrySource(vertices: vertices)],elements:[SCNGeometryElement(indices: indices, primitiveType:.triangles)]))
//        node.scale = SCNVector3(1,1,1);
//        node.position = SCNVector3(0,0,0);
        scnView.scene?.rootNode.addChildNode(graphnode!)
//        let rotateAction = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: .pi, z: 0, duration: 5))
//        node.runAction(rotateAction)
    }
    
}



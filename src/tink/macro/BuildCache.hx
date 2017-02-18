package tink.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import tink.macro.TypeMap;

using haxe.macro.Tools;

typedef BuildContextN = {
  pos:Position,
  types:Array<Type>,
  usings:Array<TypePath>,
  name:String,
}


typedef BuildContext = {
  pos:Position,
  type:Type,
  usings:Array<TypePath>,
  name:String,
}

typedef BuildContext2 = {>BuildContext,
  type2:Type,
}

typedef BuildContext3 = {>BuildContext2,
  type3:Type,
}

class BuildCache { 
  
  static var cache = new Map();
  
  static public function getType3(name, ?types, ?pos:Position, build:BuildContext3->TypeDefinition) {
     if (types == null)
      switch Context.getLocalType() {
        case TInst(_.toString() == name => true, [t1, t2, t3]):
          types = { t1: t1, t2: t2, t3: t3 };
        default:
          throw 'assert';
      }  
      
    var t1 = types.t1.toComplexType(),
        t2 = types.t2.toComplexType(),
        t3 = types.t2.toComplexType();
        
    return getType(name, (macro : { t1: $t1, t2: $t2, t3: $t3 } ).toType(), pos, function (ctx) return build({
      type: types.t1,
      type2: types.t2,
      type3: types.t3,
      pos: ctx.pos,
      name: ctx.name,
      usings: ctx.usings
    }));   
  }
  
  static public function getTypeN(name, ?types, ?pos:Position, build:BuildContextN->TypeDefinition) {
    
    if (pos == null)
      pos = Context.currentPos();
    
    if (types == null)
      switch Context.getLocalType() {
        case TInst(_.toString() == name => true, params):
          types = params;
        default:
          throw 'assert';
      }  
      
    var compound = ComplexType.TAnonymous([for (i in 0...types.length) {
      name: 't$i',
      pos: pos,
      kind: FVar(types[i].toComplexType()),
    }]).toType();
        
    return getType(name, compound, pos, function (ctx) return build({
      types: types,
      pos: ctx.pos,
      name: ctx.name,
      usings: ctx.usings
    }));
  }  
  
  static public function getType2(name, ?types, ?pos:Position, build:BuildContext2->TypeDefinition) {
    if (types == null)
      switch Context.getLocalType() {
        case TInst(_.toString() == name => true, [t1, t2]):
          types = { t1: t1, t2: t2 };
        default:
          throw 'assert';
      }  
      
    var t1 = types.t1.toComplexType(),
        t2 = types.t2.toComplexType();
        
    return getType(name, (macro : { t1: $t1, t2: $t2 } ).toType(), pos, function (ctx) return build({
      type: types.t1,
      type2: types.t2,
      pos: ctx.pos,
      name: ctx.name,
      usings: ctx.usings
    }));
  }
  
  static public function getType(name, ?type, ?pos:Position, build:BuildContext->TypeDefinition) {
    
    if (pos == null)
      pos = Context.currentPos();
    
    if (type == null)
      switch Context.getLocalType() {
        case TInst(_.toString() == name => true, [v]):
          type = v;
        case TInst(_.toString() == name => true, _):
          Context.fatalError('type parameter expected', pos);
        case TInst(_.get() => { pos: pos }, _):
          Context.fatalError('Expected $name', pos);
        default:
          throw 'assert';
      }  
      
    var forName = 
      switch cache[name] {
        case null: cache[name] = new Group(name);
        case v: v;
      }
    
    return forName.get(type, pos, build);  
  }
}

private typedef Entry = {
  name:String,
}

private class Group {
  
  var name:String;
  var counter = 0;
  var entries = new TypeMap<Entry>();
  
  public function new(name) {
    this.name = name;
  }
  
  public function get(type:Type, pos:Position, build:BuildContext->TypeDefinition):Type {
    
    function make(path:String) {
      var usings = [];
      var def = build({
        pos: pos, 
        type: type, 
        usings: usings, 
        name: path.split('.').pop()
      });
      
      Context.defineModule(path, [def], usings);
      entries.set(type, { name: path } );
      return Context.getType(path);
    }
    
    return 
      switch entries.get(type) {
        case null:
          var ret = null;
          while (ret == null) {
            try {
              Context.getType('$name$counter');
            }
            catch (e:Dynamic) { 
              ret = make('$name$counter');
            }
            counter++;
          }
          ret;
        case v:
          try {
            Context.getType(v.name);
          }
          catch (e:Dynamic) {
            make(v.name);
          }
      }
  }
}
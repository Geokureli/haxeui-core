package haxe.ui.core;

import haxe.ui.util.Variant;

@:dox(hide) @:noCompletion
class ValueBehaviour extends Behaviour {
    private var _value:Variant;
    
    public function new(component:Component, defaultValue:Variant = null) {
        super(component);
        if (defaultValue != null) {
            _value = defaultValue;
        }
    }
    
    public override function get():Variant {
        return _value;
    }
    
    public override function set(value:Variant) {
        if (value == _value) {
            return;
        }

        _value = value;
        _component.invalidateData();
    }
}

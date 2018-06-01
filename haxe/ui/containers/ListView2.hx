package haxe.ui.containers;

import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.ScrollView2;
import haxe.ui.core.Behaviour;
import haxe.ui.core.ClassFactory;
import haxe.ui.core.Component;
import haxe.ui.core.DataBehaviour;
import haxe.ui.core.IDataComponent;
import haxe.ui.core.ItemRenderer;
import haxe.ui.core.LayoutBehaviour;
import haxe.ui.core.ScrollEvent;
import haxe.ui.core.UIEvent;
import haxe.ui.data.DataSource;
import haxe.ui.data.transformation.NativeTypeTransformer;
import haxe.ui.layouts.LayoutFactory;
import haxe.ui.layouts.ScrollViewLayout;
import haxe.ui.util.Variant;

class ListView2 extends ScrollView2 implements IDataComponent {
    //***********************************************************************************************************
    // Public API
    //***********************************************************************************************************
    @:behaviour(DataSourceBehaviour)                    public var dataSource:DataSource<Dynamic>;
    @:behaviour(LayoutBehaviour, 30)                    public var itemWidth:Float;
    @:behaviour(LayoutBehaviour, 30)                    public var itemHeight:Float;
    @:behaviour(LayoutBehaviour, false)                 public var variableItemSize:Bool;
//    @:behaviour(ItemRendererClassBehaviour)             public var itemRendererClass:Class<ItemRenderer>;
//    @:behaviour(ItemRendererFunctionBehaviour)          public var itemRendererFunction:ItemRendererFunction2;
    @:behaviour(SelectedIndexBehaviour, -1)             public var selectedIndex:Int;
    @:behaviour(SelectedItemBehaviour)                  public var selectedItem:Component;  //TODO :ItemRenderer - Variant error

    //***********************************************************************************************************
    // Internals
    //***********************************************************************************************************
    private override function createDefaults() { // TODO: remove this eventually, @:layout(...) or something
        super.createDefaults();
        _defaultLayout = new VerticalVirtualLayout();
    }

    public function new() { // TEMP!
        super();

        registerEvent(ScrollEvent.CHANGE, function(e) {
            invalidateComponentLayout();
        }); //TODO;
    }

    private override function validateComponentData() {
        super.validateComponentData();

        // TODO: temp
        var contents:Component = findComponent("scrollview-contents", false, "css");
        if (virtual == true && Std.is(contents.layout, Absolute) == false) {
            contents.layout = LayoutFactory.createFromName("absolute");
        }
    }
}

typedef ItemRendererFunction2 = Dynamic->Int->ClassFactory<ItemRenderer>;    //(data, index):ClassFactory<ItemRenderer>

@:dox(hide) @:noCompletion
class VirtualLayout extends ScrollViewLayout {
    private var _firstIndex:Int = -1;
    private var _lastIndex:Int = -1;
    private var _rendererPool:Array<ItemRenderer> = [];
    private var _sizeCache:Array<Int> = [];

    private var _contents:Component;
    private var contents(get, null):Component;
    private function get_contents():Component {
        if (contents == null) {
            contents = findComponent("scrollview-contents", false, "css");
        }

        return contents;
    }

    private var dataSource(get, never):DataSource<Dynamic>;
    private function get_dataSource():DataSource<Dynamic> {
        return cast(_component, IDataComponent).dataSource;
    }

    public override function refresh() {
        refreshData();

        super.refresh();
    }

    private function refreshData() {
        if (dataSource == null) {
            return;
        }

        var comp:ScrollView2 = cast(_component, ScrollView2);
        if (comp.virtual == false) {
            refreshNonVirtualData();
        } else {
            refreshVirtualData();
        }
    }

    private function refreshNonVirtualData() {
        var dataSource:DataSource<Dynamic> = dataSource;
        var contents:Component = this.contents;
        for (n in 0...dataSource.size) {
            var data:Dynamic = dataSource.get(n);

            if (n < contents.childComponents.length) {
                var cls = itemClass(n, data);
                var item:ItemRenderer = cast contents.childComponents[n];
                if (Std.is(item, cls)) {
                } else {
                    _component.removeComponent(item);
                    var item = Type.createInstance(cls, []);
                    _component.addComponentAt(item, n);
                }

                item.data = data;
            } else {
                var cls = itemClass(n, data);
                var item:ItemRenderer = cast Type.createInstance(cls, []);
                item.data = data;
                _component.addComponent(item);
            }
        }

        while (dataSource.size < contents.childComponents.length) {
            contents.removeComponent(contents.childComponents[contents.childComponents.length - 1]); // remove last
        }
    }

    private function refreshVirtualData() {
        removeInvisibleRenderers();
        calculateRangeVisible();
        updateScroll();

        // TODO: temp
        var usableSize = this.usableSize;
        contents.height = usableSize.height;
        contents.width = usableSize.width;
        //

        var dataSource:DataSource<Dynamic> = dataSource;
        var i = 0;
        for (n in _firstIndex..._lastIndex) {
            var data:Dynamic = dataSource.get(n);

            var item:ItemRenderer = null;
            var cls = itemClass(n, data);
            if (contents.childComponents.length <= i) {
                item = getRenderer(cls);
                _component.addComponent(item);
            } else {
                item = cast contents.childComponents[i];

                //Renderers are always ordered
                if (!Std.is(item, cls)) {
                    item = getRenderer(cls);
                    _component.addComponentAt(item, i);
                } else if (item.itemIndex != n) {
                    _component.setComponentIndex(item, i);
                }

                var className:String = n % 2 == 0 ? "even" : "odd";
                if (!item.hasClass(className)) {
                    var inverseClassName = n % 2 == 0 ? "odd" : "even";
                    item.removeClass(inverseClassName);
                    item.addClass(className);
                }
            }

            item.data = data;
            item.itemIndex = n;

            i++;
        }

        while (contents.childComponents.length > i) {
            removeRenderer(cast contents.childComponents[contents.childComponents.length - 1]);    // remove last
        }
    }

    private function calculateRangeVisible() {

    }

    private function updateScroll() {

    }

    private function itemClass(index:Int, data:Dynamic):Class<Component> { // all temp
//        return Renderer1;
        if (index == 3) {
//            return Renderer3;
        }

        if (index % 2 == 0) {
            return Renderer1;
        } else {
            return Renderer2;
        }

        return null;
    }

    private function getRenderer(cls:Class<Component>):ItemRenderer {
        for (i in 0..._rendererPool.length) {
            var renderer = _rendererPool[i];
            if (Std.is(renderer, cls)) {
                _rendererPool.splice(i, 1);
                return renderer;
            }
        }

        var instance = Type.createInstance(cls, []);
        if(!Std.is(instance, ItemRenderer))
            throw 'Renderer isn\'t a ItemRenderer class';

        return cast(instance, ItemRenderer);
    }

    private function removeRenderer(renderer:ItemRenderer) {
        _component.removeComponent(renderer);
        renderer.itemIndex = -1;
        _rendererPool.push(cast(renderer, ItemRenderer));
    }

    private function removeInvisibleRenderers() {
        var contents:Component = findComponent("scrollview-contents", false, "css");
        if (_firstIndex >= 0) {
            while (contents.childComponents.length > 0 && !isRendererVisible(contents.childComponents[0])) {
                removeRenderer(cast contents.childComponents[0]);
                ++_firstIndex;
            }
        }

        if (_lastIndex >= 0) {
            while (contents.childComponents.length > 0 && !isRendererVisible(contents.childComponents[contents.childComponents.length - 1])) {
                removeRenderer(cast contents.childComponents[contents.childComponents.length - 1]);
                --_lastIndex;
            }
        }
    }

    private function isRendererVisible(renderer:Component):Bool {
        return renderer.top < _component.componentHeight &&
        renderer.top + renderer.componentHeight >= 0 &&
        renderer.left < _component.componentWidth &&
        renderer.left + renderer.componentWidth >= 0;
    }
}

class VerticalVirtualLayout extends VirtualLayout {
    private override function repositionChildren() {
        super.repositionChildren();

        var comp:ListView2 = cast(_component, ListView2);   //TODO - interface
        if (comp.virtual == true) {
            var usableSize = this.usableSize;
            var contents:Component = findComponent("scrollview-contents", false, "css");
            var verticalSpacing = contents.layout.verticalSpacing;
            var itemHeight = comp.itemHeight;
            var n:Int = _firstIndex;

            if (comp.variableItemSize == true) {
                for (child in contents.childComponents) {
                    //TODO
                    ++n;
                }
            } else {
                for (child in contents.childComponents) {
                    child.top = (n * (itemHeight + verticalSpacing)) - comp.vscrollPos;
                    ++n;
                }
            }
        }
    }

    private override function calculateRangeVisible() {
        var comp:ListView2 = cast(_component, ListView2);   //TODO - interface
        var verticalSpacing = contents.layout.verticalSpacing;
        var itemHeight = comp.itemHeight;
        var visibleItemsCount:Int = 0;

        if (comp.variableItemSize == true) {
            //TODO
        } else {
            visibleItemsCount = Math.ceil(contents.height / (itemHeight + verticalSpacing));
            _firstIndex = Std.int(comp.vscrollPos / (itemHeight + verticalSpacing));
        }

        if (_firstIndex < 0) {
            _firstIndex = 0;
        }

        _lastIndex = _firstIndex + visibleItemsCount + 1;
        if (_lastIndex > dataSource.size) {
            _lastIndex = dataSource.size;
        }
    }

    private override function updateScroll() {
        var comp:ListView2 = cast(_component, ListView2);   //TODO - interface
        var usableSize = this.usableSize;
        var dataSize:Int = dataSource.size;
        var verticalSpacing = contents.layout.verticalSpacing;
        var itemHeight = comp.itemHeight;
        var scrollMax:Float = 0;

        if (comp.variableItemSize == true) {
            //TODO
        } else {
            scrollMax = (dataSize * itemHeight + ((dataSize - 1) * verticalSpacing)) - usableSize.height;
        }

        if (scrollMax < 0) {
            scrollMax = 0;
        }

        comp.vscrollMax = scrollMax;
        comp.vscrollPageSize = (usableSize.height / (scrollMax + usableSize.height)) * scrollMax;
    }
}

private class DataSourceBehaviour extends DataBehaviour {
    public override function set(value:Variant) {
        super.set(value);
        var dataSource:DataSource<Dynamic> = _value;
        if (dataSource != null) {
            dataSource.transformer = new NativeTypeTransformer();
            dataSource.onChange = _component.invalidateComponentData;
        }
    }
}

private class RendererTest extends ItemRenderer {   // TODO: temp

    public function new() {
        super();

        percentWidth = 100;
        componentHeight = 30;
    }

    override private function validateComponentData() {
        super.validateComponentData();

        if (data != null) {
            findComponent(Label, true).text = data.text;
            findComponent(Button, true).text = data.text;
        }
    }

    override private function validateComponentLayout():Bool {
        return super.validateComponentLayout();
    }

}

private class Renderer1 extends RendererTest { // TODO: temp
    public function new() {
        super();

        percentWidth = 100;
        componentHeight = 30;
        //backgroundColor = 0xecf2f9;

        var hbox = new HBox();
        hbox.percentWidth = 100;

        var label = new Label();
        label.percentWidth = 100;
        label.verticalAlign = "center";
        hbox.addComponent(label);

        var button = new Button();
        button.verticalAlign = "center";
        hbox.addComponent(button);

        addComponent(hbox);
    }
}

private class Renderer2 extends RendererTest { // TODO: temp
    public function new() {
        super();

        percentWidth = 100;
        componentHeight = 30;
        //backgroundColor = 0xCCFFCC;
        backgroundColor = 0xecf2f9;

        var hbox = new HBox();
        hbox.percentWidth = 100;

        var button = new Button();
        button.verticalAlign = "center";

        var label = new Label();
        label.percentWidth = 100;
        label.verticalAlign = "center";
        hbox.addComponent(label);
        hbox.addComponent(button);

        addComponent(hbox);
    }
}


private class Renderer3 extends RendererTest { // TODO: temp
    public function new() {
        super();

        percentWidth = 100;
        componentHeight = 130;
        //backgroundColor = 0xFF0000;

        var hbox = new HBox();
        hbox.percentWidth = 100;

        var button = new Button();
        button.height = componentHeight;

        var label = new Label();
        label.percentWidth = 100;
        label.verticalAlign = "center";

        hbox.addComponent(label);
        hbox.addComponent(button);

        addComponent(hbox);
    }
}

//***********************************************************************************************************
// Behaviours
//***********************************************************************************************************

private class SelectedIndexBehaviour extends DataBehaviour {
    private var _currentSelection:ItemRenderer;

    private override function validateData() {
        var listView:ListView2 = cast(_component, ListView2);
        var selectedItem:ItemRenderer = cast listView.selectedItem;
        if(_currentSelection != selectedItem)
        {
            if (_currentSelection != null) {
                _currentSelection.removeClass(":selected", true, true);
            }

            _currentSelection = selectedItem;

            if (_currentSelection != null) {
                _currentSelection.addClass(":selected", true, true);
                _component.dispatch(new UIEvent(UIEvent.CHANGE));
            }
        }
    }
}

//***********************************************************************************************************
// Behaviours
//***********************************************************************************************************
private class SelectedItemBehaviour extends Behaviour {
    public override function get():Variant {
        var listView:ListView2 = cast(_component, ListView2);
        var contents:Component = _component.findComponent("scrollview-contents", false, "css");
        if (contents != null && listView.selectedIndex != -1 && listView.selectedIndex < contents.childComponents.length) {
            return cast(contents.childComponents[listView.selectedIndex], ItemRenderer);
        } else {
            return null;
        }
    }

    public override function set(value:Variant) {
        var listView:ListView2 = cast(_component, ListView2);
        var contents:Component = _component.findComponent("scrollview-contents", false, "css");
        if (listView.dataSource != null && contents != null) {
            listView.selectedIndex = contents.childComponents.indexOf(value);
        }
    }
}
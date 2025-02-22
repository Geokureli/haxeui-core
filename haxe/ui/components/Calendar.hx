package haxe.ui.components;

import haxe.ui.behaviours.Behaviour;
import haxe.ui.behaviours.DataBehaviour;
import haxe.ui.behaviours.DefaultBehaviour;
import haxe.ui.containers.Grid;
import haxe.ui.core.CompositeBuilder;
import haxe.ui.events.Events;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.layouts.VerticalGridLayout;
import haxe.ui.util.Variant;

class CalendarEvent extends UIEvent {
    public static inline var DATE_CHANGE:String = "datechange";

    public override function clone():CalendarEvent {
        var c:CalendarEvent = new CalendarEvent(this.type);
        c.type = this.type;
        c.bubble = this.bubble;
        c.target = this.target;
        c.data = this.data;
        c.canceled = this.canceled;
        postClone(c);
        return c;
    }
}

/**
 * A grid style calendar display, that allows ou to scroll date, month and year.
 */
@:composite(Events, Builder, Layout)
class Calendar extends Grid {
    //***********************************************************************************************************
    // Public API
    //***********************************************************************************************************

    /**
     * Most of the time the same as `selectedDate`, But has to be visible to the calendar.
     * 
     * That means, if you move the calendar to the next month, the `date` will be the first day of the next month,
     * because the `selectedDate` is no longer visible.
     */
    @:clonable @:behaviour(DateBehaviour)                   public var date:Date;

    /**
     * The selected date.
     */
    @:clonable @:behaviour(SelectedDateBehaviour)           public var selectedDate:Date;

    /**
     * Moves the calendar a month backwards.
     */
    @:call(PreviousMonthBehaviour)                          public function previousMonth();

    /**
     * Moves the calendar a month forward.
     */
    @:call(NextMonthBehaviour)                              public function nextMonth();

    /**
     * Moves the calendar a year backwards.
     */
    @:call(PreviousYearBehaviour)                           public function previousYear();

    /**
     * Moves the calendar a year forward.
     */
    @:call(NextYearBehaviour)                               public function nextYear();

    //***********************************************************************************************************
    // Internals
    //***********************************************************************************************************
    private override function createDefaults() {
        super.createDefaults();
        _defaultLayoutClass = Layout;
    }
}

//***********************************************************************************************************
// Behaviours
//***********************************************************************************************************
private class PreviousMonthBehaviour extends Behaviour {
    public override function call(param:Any = null):Variant {
        var calendar = cast(_component, Calendar);
        calendar.date = DateUtils.previousMonth(calendar.date);
        return null;
    }
}

private class NextMonthBehaviour extends Behaviour {
    public override function call(param:Any = null):Variant {
        var calendar = cast(_component, Calendar);
        calendar.date = DateUtils.nextMonth(calendar.date);
        return null;
    }
}

private class PreviousYearBehaviour extends Behaviour {
    public override function call(param:Any = null):Variant {
        var calendar = cast(_component, Calendar);
        calendar.date = DateUtils.previousYear(calendar.date);
        return null;
    }
}

private class NextYearBehaviour extends Behaviour {
    public override function call(param:Any = null):Variant {
        var calendar = cast(_component, Calendar);
        calendar.date = DateUtils.nextYear(calendar.date);
        return null;
    }
}

private class SelectedDateBehaviour extends DefaultBehaviour {
    public override function set(value:Variant) {
        super.set(value);

        var date:Date = value;
        _component.invalidateComponentData();
        var calendar = cast(_component, Calendar);
        calendar.date = date; // TODO: this is wrong, works, but its wrong... need to split up the code into util classes, one to build the month, another to select it

        _component.dispatch(new UIEvent(UIEvent.CHANGE));
    }
}

@:access(haxe.ui.core.Component)
private class DateBehaviour extends DataBehaviour {
    private override function validateData() {
        var date:Date = _value;

        if (date == null) {
            return;
        }

        var year = date.getFullYear();
        var month = date.getMonth();

        var startDay:Int = new Date(year, month, 1, 0, 0, 0).getDay();
        var endDay:Int = DateUtils.getEndDay(month, year);

        for (child in _component.childComponents) {
            child.opacity = .3;
            child.removeClass("calendar-off-day");
            child.removeClass("calendar-day");
            child.removeClass("calendar-day-selected");
            child.removeClass(":hover"); // bit of a hack, kinda, when use in a dropdown, it never gets the mouseout as the calendar is removed
        }

        var prevMonth = DateUtils.previousMonth(date);
        var last = DateUtils.getEndDay(prevMonth.getMonth(), prevMonth.getFullYear());

        var n = (startDay - 1);
        for (_ in 0...(startDay)) {
            var item = _component.childComponents[n];
            item.addClass("calendar-off-day");
            n--;
            item.text = "" + last;
            last--;
        }

        var selectedDate:Date = cast(_component, Calendar).selectedDate;
        if (selectedDate == null) {
            selectedDate = Date.now();
        }

        for (i in 0...endDay) {
            var item = _component.childComponents[i + startDay];
            item.addClass("calendar-day");
            item.opacity = 1;
            item.hidden = false;
            item.text = "" + (i + 1);
            if (i + 1 == selectedDate.getDate() && month == selectedDate.getMonth() && year == selectedDate.getFullYear()) {
                item.addClass("calendar-day-selected");
            }

            last = i + startDay;
        }

        last++;
        var n:Int = 0;
        for (i in last..._component.childComponents.length) {
            var item = _component.childComponents[i];
            item.addClass("calendar-off-day");
            item.text = "" + (n + 1);
            n++;
        }

        _component.registerInternalEvents(true);

        _component.dispatch(new CalendarEvent(CalendarEvent.DATE_CHANGE));
    }
}

//***********************************************************************************************************
// Utils
//***********************************************************************************************************
private class DateUtils {
    public static function getEndDay(month:Int, year:Int):Int {
        var endDay:Int = -1;
        switch (month) {
            case 1: // feb
                if ((year % 400 == 0) ||  ((year % 100 != 0) && (year % 4 == 0))) {
                    endDay = 29;
                } else {
                    endDay = 28;
                }
            case 3, 5, 8, 10: // april, june, sept, nov.
                endDay = 30;
            default:
                endDay = 31;

        }
        return endDay;
    }

    public static function previousMonth(date:Date):Date {
        var year = date.getFullYear();
        var month = date.getMonth();
        var day = date.getDate();

        month--;
        if (month < 0) {
            month = 11;
            year--;
        }
        day = cast(Math.min(day, getEndDay(month, year)), Int);
        date = new Date(year, month, day, 0, 0, 0);
        return date;
    }

    public static function nextMonth(date:Date):Date {
        var year = date.getFullYear();
        var month = date.getMonth();
        var day = date.getDate();

        month++;
        if (month > 11) {
            month = 0;
            year++;
        }
        day = cast(Math.min(day, getEndDay(month, year)), Int);
        date = new Date(year, month, day, 0, 0, 0);
        return date;
    }

    public static function previousYear(date:Date):Date {
        var year = date.getFullYear();
        var month = date.getMonth();
        var day = date.getDate();

        year--;
        day = cast(Math.min(day, getEndDay(month, year)), Int);
        date = new Date(year, month, day, 0, 0, 0);
        return date;
    }

    public static function nextYear(date:Date):Date {
        var year = date.getFullYear();
        var month = date.getMonth();
        var day = date.getDate();

        year++;
        day = cast(Math.min(day, getEndDay(month, year)), Int);
        date = new Date(year, month, day, 0, 0, 0);
        return date;
    }
}

//***********************************************************************************************************
// Events
//***********************************************************************************************************
private class Events extends haxe.ui.events.Events {
    public override function register() {
        unregister();
        for (child in _target.childComponents) {
            if (child.hasEvent(MouseEvent.CLICK, onDayClicked) == false && child.hasClass("calendar-day")) {
                child.registerEvent(MouseEvent.CLICK, onDayClicked);
            }
        }
    }

    public override function unregister() {
        for (child in _target.childComponents) {
            child.unregisterEvent(MouseEvent.CLICK, onDayClicked);
        }
    }

    private function onDayClicked(event:MouseEvent) {
        var calendar:Calendar = cast(_target, Calendar);
        var day:Int = Std.parseInt(event.target.text);
        var month = calendar.date.getMonth();
        var year = calendar.date.getFullYear();
        calendar.selectedDate = new Date(year, month, day, 0, 0, 0);
    }
}

//***********************************************************************************************************
// Composite Builder
//***********************************************************************************************************
private class Builder extends CompositeBuilder {
    private var _calendar:Calendar;

    public function new(calendar:Calendar) {
        super(calendar);
        _calendar = calendar;
    }

    public override function create() {
        _calendar.columns = 7; // this is really strange, this does work here!

        for (_ in 0...6) {
            for (_ in 0...7) {
                var item = new Button();
                item.scriptAccess = false;
                _calendar.addComponent(item);
            }
        }

        //_calendar.syncComponentValidation();
        _calendar.date = Date.now();
    }
}

//***********************************************************************************************************
// Composite Layout
//***********************************************************************************************************
@:dox(hide) @:noCompletion
private class Layout extends VerticalGridLayout {
    private override function resizeChildren() {
        var max:Float = 0;
        for (child in component.childComponents) {
            if (child.layout == null) {
                continue;
            }
            if (child.width > child.layout.paddingLeft + child.layout.paddingRight && child.width > max) {
                max = child.width;
            }
            if (child.width > child.layout.paddingTop + child.layout.paddingBottom && child.height > max) {
                max = child.height;
            }
        }
        if (max > 0) {
            for (child in component.childComponents) {
                child.width = max;
                child.height = max;
            }
        }
        //super.resizeChildren();
    }
}
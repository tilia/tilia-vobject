tilia/vobject
=============

[![Build Status](https://travis-ci.org/tilia/tilia-vobject.svg?branch=master)](https://travis-ci.org/tilia/tilia-vobject)

**tilia/vobject is a port of [sabre/vobject](https://github.com/fruux/sabre-vobject)**

The sabre/vobject library allows you to easily parse and manipulate [iCalendar](https://tools.ietf.org/html/rfc5545)
and [vCard](https://tools.ietf.org/html/rfc6350) objects using PHP.

The goal of the VObject library is to create a very complete library, with an easy to use API.


Installation
------------

Simply add tilia-vobject to your Gemfile and bundle it up:

```ruby
  gem 'tilia-vobject', '~> 4.0.0'
```

Changes to sabre/vobject
------------------------

```php
  Sabre\VObject\FreeBusyGenerator#setTimeRange(DateTimeInterface $start = null, DateTimeInterface $end = null)
```

is replaced by

```ruby
  Tilia::VObject::FreeBusyGenerator#time_range=(Range<Time>)
```

Unknown beginnings and ends can be replaced by `Tilia::VObject::Settings.min_date`
and `.max_date`.


```php
  Sabre\VObject\Property\ICalendar\DateTime#setDateTime(DateTimeInterface $dt, $isFloating = false)
  Sabre\VObject\Property\ICalendar\DateTime#setDateTimes(array $dt, $isFloating = false)
```

are replaced by

```ruby
  Tilia::VObject::Property::ICalendar#date_time=(Time)
  Tilia::VObject::Property::ICalendar#date_times=(Array<Time>)
  Tilia::VObject::Property::ICalendar#floating=(Boolean)
```


Contributing
------------

See [Contributing](CONTRIBUTING.md)


License
-------

tilia-vobject is licensed under the terms of the [three-clause BSD-license](LICENSE).

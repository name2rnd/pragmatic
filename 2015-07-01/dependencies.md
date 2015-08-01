# Работа с зависимостями

__Практическая статья про инструменты анализа зависимостей.__

В этот раз хочется немного рассказать про инструменты, которые я использую, когда нужно найти последовательность загрузки модулей или виновника, который загружает что-то лишнее. Не всегда бывает очевидно, не всегда grep способен решить проблемы.

Кроме того, такие инструменты дают общее представление, какие именно и откуда модули подгрузились для выполнения задачи. И, к удивлению, иногда их бывает значительно больше, чем ожидаешь, а порой там можно найти самые неожиданные вещи.

_Предыстория_: была у меня как-то очень простая задача - расширить функционал программы, используя уже готовую библиотеку. Задача решилась, но скорость старта (не работы, а именно старта) упала до уровня, заметного человеку. Это очень подозрительно, если знаешь, что объективных причин на это нет. Не стоит игнорировать такие симптомы.

_(Все представленные ниже примеры выдуманы из пальца и упрощены до предела для наглядности)_

Например, есть вот такая программа:

```perl
use strict; use warnings; use feature qw/say/;
use lib::abs qw/./;

# do something cool
say 'OK';

exit(0);
```

Она делает что-то полезное и важное, но мы хотим сделать ее еще полезнее, а нужное уже есть в другой библиотеке **Utils**. Подключи и используй.
Пусть это будет такая библиотека Utils:

```perl
package Utils;
use strict; use warnings; use feature qw/say/;
use Common;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(a);

sub a {
    say 'a';
}

1;
```

Любой нормальный человек подключает эту библиотеку и наслаждается жизнью с готовым функционалом.

```perl
use Utils qw/a/;
a();
```

```
$ perl main.pl
a
OK
```

Для повышения запутанности связей модулей я сделала еще такой **Common**:

```perl
package Common;
use Abc;
use DateTime;
1;
```

и **Abc**:

```perl
package Abc;
use DateTime;
1;
```

Пример построен таким образом, что в результате формируются следующие зависимости:

```
main.pl
|-- Utils
    |-- Common
        |-- Datetime
        |-- Abc
            |-- Datetime
```

В реальности - вам ничего о них неизвестно, поэтому представим, что мы о них не знаем.

## perl -d

Если вы ничего не знаете о "-d", тогда вам сюда: http://perldoc.perl.org/perldebug.html.
Perl debugger отлично показывает все загруженные модули. Давайте начнем с общего списка:

```
$ perl -d main.pl
...
main::(main.pl:5):	a();

  DB<1> M

'Abc.pm' => '/home/wwax/Desktop/pragmatic/2/Abc.pm'
'Carp.pm' => '1.29 from /usr/share/perl/5.18/Carp.pm'
'Class/Singleton.pm' => '1.5 from /usr/local/share/perl/5.18.2/Class/Singleton.pm'
'Cwd.pm' => '3.40 from /usr/lib/perl/5.18/Cwd.pm'
'DateTime.pm' => '1.19 from /usr/local/lib/perl/5.18.2/DateTime.pm'
'DateTime/Duration.pm' => '1.19 from /usr/local/lib/perl/5.18.2/DateTime/Duration.pm'
'DateTime/Helpers.pm' => '1.19 from /usr/local/lib/perl/5.18.2/DateTime/Helpers.pm'
```

Команда **M** показывает список всех загруженных модулей. Но подождите! Я же только подключила Utils, а там нет никакого DateTime! Он мне вообще не нужен, поэтому надо бы избавиться, чтобы не притягивать лишнего.

Смотрим, где он у нас подключается.

```
$ perl -d main.pl
...

  DB<1> b load /usr/local/lib/perl/5.18.2/DateTime.pm
Will stop on load of '/usr/local/lib/perl/5.18.2/DateTime.pm'.

  DB<2> R
'/usr/local/lib/perl/5.18.2/DateTime.pm' loaded...

DateTime::CODE(0x1e58ce8)(/usr/local/lib/perl/5.18.2/DateTime.pm:9):
9:	our $VERSION = '1.19';

  DB<2> T
@ = DB::DB called from file '/usr/local/lib/perl/5.18.2/DateTime.pm' line 9
$ = require 'DateTime.pm' called from file '/home/wwax/Desktop/pragmatic/2/Abc.pm' line 2
....
```

**b load /usr/local/lib/perl/5.18.2/DateTime.pm** - установили точку останова на момент, когда будет выполняться первая инструкция этого модуля. Имя файла беру из списка загруженных модулей, полученных по команде **M**.
**R** - перезапуск дебаггера, который затем остановился на строке 9 файла DateTime.pm.
**Т** - трассировка вызовов. Во второй строке видно, что: 

```
require 'DateTime.pm' called from file '/home/wwax/Desktop/pragmatic/2/Abc.pm' line 2
```

наш модуль подключается в другом модуле **ABC**, в строке 2.

Это отличный инструмент!

Закомметируем здесь **#use DateTime;**. Ну просто посмотреть, что будет.
Опять смотрим в **perl -d**, команда **M**. Но не может быть! Кто-то еще подключил DateTime.pm.
Опять точка останова, опять трассировка. Только в этот раз DateTime подключил какой-то другой модуль с именем Common.pm...
И так можно продолжать довольно долго, быстро надоедает.

## Visually graphing
Есть вот такой невероятный инструмент: https://metacpan.org/pod/App::PrereqGrapher, о котором можно почитать тут: http://blogs.perl.org/users/neilb/2012/12/prereq-grapher.html

Запустим:
```
$ prereq-grapher -nc main.pl
```

Эта команда сгенерировала файл **dependencies.dot**, который можно превратить в **png**:
```
$ dot -Tpng dependencies.dot > output.png
```

Граф зависимостей в наших руках! 

![Граф зависимостей](https://raw.githubusercontent.com/name2rnd/pragmatic/master/output.png "Deps")

На графе очевидно, кто из модулей подключает DateTime, и сколько всего он еще тянет за собой. А все ради использования одной только функции **a()**. Ужас! Этот граф построен с использованием флага **-nc**, что значит - не выводить _core modules_. 

## Если ничего не помогает
Не так давно мне открылась мощь утилиты **strace** (понятное дело, что **grep** иногда дает ответ быстрее, но случаи бывают разные, и еще не всегда очевидно, где именно искать). Для меня, как человека, пишущего на С только в академическо-институтских целях, открылся новый мир средств отладки.
(Если у меня здесь есть примеры неправильного использования - очень прошу мне о них сообщить)

Запускаем и отправляем вывод в лог.

```
$ strace perl main.pl &> strace.log
```

Смотрим, какие вызовы обращались к чему-нибудь с **DateTime**

```
$ cat strace.log | grep DateTime.pm -C 5 | less
stat("/home/wwax/Desktop/pragmatic/2/Abc.pm", {st_mode=S_IFREG|0664, st_size=30, ...}) = 0
open("/home/wwax/Desktop/pragmatic/2/Abc.pm", O_RDONLY) = 6
ioctl(6, SNDCTL_TMR_TIMEBASE or SNDRV_TIMER_IOCTL_NEXT_DEVICE or TCGETS, 0x7ffdd665dd60) = -1 ENOTTY (Inappropriate ioctl for device)
lseek(6, 0, SEEK_CUR)                   = 0
read(6, "package Abc;\nuse DateTime;\n1;\n", 8192) = 30
...
stat("/usr/local/lib/perl/5.18.2/DateTime.pm", {st_mode=S_IFREG|0444, st_size=122107, ...}) = 0
open("/usr/local/lib/perl/5.18.2/DateTime.pm", O_RDONLY) = 7

```

Это, конечно, уже совсем тяжелый случай, если мы говорим о _perl_. Но средства отладки, на мой взгляд, это первые необходимые инструменты для упрощения своей жизни.

А как разрешать найденную нами избыточную зависимость - это уже зависит от конкретного проекта и ваших архитектурных взглядов.
Успехов!

Наталья Савенкова

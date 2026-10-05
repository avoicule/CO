# TU Delft CSE1100 — Object-Oriented Programming (Java)
# Practice Exam (original questions, exam-style)

**Style basis:** Modelled on the TU Delft CSE1100 "Object-Oriented Programming / Introduction
to Programming" course (BSc Computer Science & Engineering, year 1; Zaidman / Overklift).
These are **original practice questions** written to match the course's typical topic
coverage and format (a multiple-choice section + open coding/design questions). They are
**not** copies of any real past exam.

**Topics covered (per CSE1100 scope):** classes & objects, encapsulation, constructors,
`static` vs instance, inheritance, polymorphism & dynamic dispatch, abstract classes,
interfaces, exceptions, generics, the Collections Framework (`List`/`Set`/`Map`),
`equals`/`hashCode`, and JUnit testing.

**Suggested time:** 90 minutes. **Rules (as in CSE1100):** closed book, no digital aids.

> Answers and worked explanations are in the final section. Try everything first.

---

## Part A — Multiple Choice (code output & concepts)

For each question choose the single best answer.

### A1. What does this print?
```java
public class A {
    static int x = 1;
    int y = 1;
    A() { x++; y++; }
    public static void main(String[] args) {
        A a = new A();
        A b = new A();
        System.out.println(a.x + " " + a.y + " " + b.y);
    }
}
```
- (a) `3 2 2`
- (b) `2 2 2`
- (c) `3 3 3`
- (d) `1 2 2`

### A2. Which statement about `equals` and `hashCode` is correct?
- (a) If two objects are `equals`, they may have different hash codes.
- (b) If two objects have the same hash code, they must be `equals`.
- (c) If you override `equals`, you should also override `hashCode` to keep the contract.
- (d) `hashCode` must return a unique value for every distinct object.

### A3. What is the output?
```java
class Animal { String sound() { return "..."; } }
class Dog extends Animal { String sound() { return "Woof"; } }
class Cat extends Animal { String sound() { return "Meow"; } }

public class Main {
    public static void main(String[] args) {
        Animal[] zoo = { new Dog(), new Cat(), new Animal() };
        for (Animal a : zoo) System.out.print(a.sound() + " ");
    }
}
```
- (a) `... ... ...`
- (b) `Woof Meow ...`
- (c) compile error
- (d) `Woof Meow Woof`

### A4. Which of the following does NOT compile?
- (a) `List<String> l = new ArrayList<>();`
- (b) `List<String> l = new ArrayList<String>();`
- (c) `ArrayList<String> l = new List<>();`
- (d) `List<String> l = new LinkedList<>();`

### A5. What happens here?
```java
public class Test {
    public static void main(String[] args) {
        int[] a = new int[3];
        System.out.println(a[3]);
    }
}
```
- (a) prints `0`
- (b) prints `null`
- (c) compile error
- (d) throws `ArrayIndexOutOfBoundsException` at runtime

### A6. What does this print?
```java
public class Counter {
    private int c = 0;
    public void inc() { c++; }
    public int get() { return c; }
    public static void main(String[] args) {
        Counter a = new Counter();
        Counter b = a;
        a.inc(); b.inc();
        System.out.println(a.get() + " " + b.get());
    }
}
```
- (a) `1 1`
- (b) `2 2`
- (c) `1 2`
- (d) `2 0`

### A7. Which is true about `abstract` classes vs interfaces (Java 8+)?
- (a) A class can extend multiple abstract classes.
- (b) An interface cannot contain any method implementations.
- (c) An interface can declare `default` methods with a body; a class implements multiple interfaces.
- (d) Abstract classes cannot have constructors.

### A8. What is printed?
```java
public class Ex {
    static String f() {
        try {
            return "try";
        } finally {
            System.out.print("finally ");
        }
    }
    public static void main(String[] args) {
        System.out.println(f());
    }
}
```
- (a) `try`
- (b) `finally try`
- (c) `try finally`
- (d) `finally`

### A9. Given `Map<String,Integer> m = new HashMap<>();`, which snippet safely increments the count for key `"k"` (starting from 0 if absent)?
- (a) `m.put("k", m.get("k") + 1);`
- (b) `m.merge("k", 1, Integer::sum);`
- (c) `m.get("k")++;`
- (d) `m.add("k", 1);`

### A10. What does this print?
```java
class Base {
    Base() { print(); }
    void print() { System.out.println("Base"); }
}
class Derived extends Base {
    int v = 10;
    void print() { System.out.println("Derived v=" + v); }
}
public class Main {
    public static void main(String[] args) { new Derived(); }
}
```
- (a) `Derived v=10`
- (b) `Base`
- (c) `Derived v=0`
- (d) compile error

---

## Part B — Short Answer / Concepts

### B1.
Explain the difference between **overloading** and **overriding**. Give a one-line Java
example of each.

### B2.
What is **encapsulation** and why are fields usually declared `private`? Give one concrete
problem that encapsulation prevents.

### B3.
Explain **dynamic dispatch** (late binding). In question A3, which method call is resolved
at runtime, and based on what?

### B4.
What is the difference between a **checked** and an **unchecked** exception in Java? Give
one example of each and state when you are forced to handle or declare them.

### B5.
Why does Java require you to override `hashCode()` whenever you override `equals()` if the
objects will be used as keys in a `HashMap` or elements of a `HashSet`? Describe the bug that
appears if you don't.

---

## Part C — Coding

### C1. Class design + encapsulation (★)
Implement a class `BankAccount` with:
- a private `balance` (non-negative),
- a constructor taking an initial balance (reject negative with `IllegalArgumentException`),
- `deposit(double amount)` and `withdraw(double amount)` where both reject non-positive
  amounts, and `withdraw` throws `IllegalArgumentException` if it would overdraw,
- `getBalance()`.

Write the class. Then write **two JUnit 5 test methods**: one checking a normal
deposit+withdraw sequence, one checking that an overdraw throws.

### C2. Inheritance & polymorphism (★★)
Model shapes:
- an abstract class `Shape` with an abstract method `double area()` and a concrete
  `String describe()` that returns `"Shape with area " + area()`;
- subclasses `Circle(double r)` and `Rectangle(double w, double h)`.

Write all three classes, then a method
`double totalArea(List<Shape> shapes)` that sums the areas using polymorphism.

### C3. Generics + Collections (★★)
Write a **generic** method
```java
public static <T> Map<T, Integer> frequencies(List<T> items)
```
that returns a map from each distinct element to the number of times it appears in `items`.
Then show the output of calling it with `List.of("a","b","a","c","a","b")`.

### C4. Interface + strategy (★★★)
Define an interface `Discount { double apply(double price); }`. Provide two implementations:
`NoDiscount` (returns price unchanged) and `PercentOff(double pct)` (subtracts `pct`%).
Write a method `double checkout(double price, Discount d)` that applies the discount, and
show two example calls.

---

## ============================= ANSWER KEY =============================

### Part A
**A1 → (a) `3 2 2`.** `x` is `static` (shared): starts 1, two constructors make it 3.
`y` is per-instance: each object's `y` becomes 2. `a.x` reads the shared `3`; `a.y` and
`b.y` are each `2`.

**A2 → (c).** The contract: equal objects *must* have equal hash codes (so (a) is false);
equal hash codes do **not** imply equality — collisions are allowed (so (b) is false);
hash codes need not be unique (so (d) is false). Overriding `equals` without `hashCode`
breaks hash-based collections — hence (c).

**A3 → (b) `Woof Meow ...`.** Dynamic dispatch: the actual runtime type decides which
`sound()` runs. `Animal`'s own instance returns `"..."`.

**A4 → (c).** `List` is an interface and cannot be instantiated (`new List<>()` is illegal).
The others are valid.

**A5 → (d).** Valid indices are 0–2; `a[3]` throws `ArrayIndexOutOfBoundsException` at
runtime (it compiles fine).

**A6 → (b) `2 2`.** `b = a` copies the **reference**, not the object. Both names point to
the same `Counter`, so two `inc()` calls make the single object's `c` equal to 2.

**A7 → (c).** Java supports multiple interface implementation and `default` methods have
bodies. (a) false (single class inheritance), (b) false since Java 8 (`default`/`static`),
(d) false (abstract classes can have constructors, called via `super`).

**A8 → (b) `finally try`.** The `finally` block runs before the method actually returns, so
`"finally "` prints first; the return value `"try"` is then printed by `main`.

**A9 → (b).** `merge("k", 1, Integer::sum)` inserts 1 if absent, else adds 1 — null-safe.
(a) NPEs when the key is absent (`m.get` returns `null`); (c) you can't `++` a method call;
(d) `Map` has no `add`.

**A10 → (c) `Derived v=0`.** `Base`'s constructor calls `print()`, which is dynamically
dispatched to `Derived.print()`. But `Derived`'s field initializer `v = 10` has **not run
yet** (it runs after `super()` returns), so `v` is still its default `0`. This is the
classic "calling an overridable method from a constructor" trap.

### Part B
**B1.** *Overloading* = same method name, different parameter lists, resolved at
**compile time** (e.g. `int add(int,int)` vs `double add(double,double)`). *Overriding* =
a subclass redefines a superclass method with the **same signature**, resolved at
**runtime** (e.g. `Dog.sound()` overriding `Animal.sound()`).

**B2.** Encapsulation = hiding internal state behind methods, exposing a controlled
interface. `private` fields stop external code from putting the object in an invalid state
(e.g. a negative `balance`) and let you change the implementation without breaking callers.
Prevents: an outside class writing `account.balance = -500;` directly.

**B3.** Dynamic dispatch: when you call an overridden instance method through a supertype
reference, the JVM picks the implementation based on the object's **actual runtime class**,
not the reference's declared type. In A3, `a.sound()` is resolved at runtime per element's
real type (`Dog`, `Cat`, `Animal`).

**B4.** *Checked* exceptions extend `Exception` (not `RuntimeException`) and **must** be
caught or declared with `throws` (e.g. `IOException`). *Unchecked* exceptions extend
`RuntimeException` and need no declaration (e.g. `NullPointerException`,
`IllegalArgumentException`). The compiler enforces handling only for checked ones.

**B5.** `HashMap`/`HashSet` locate objects by `hashCode()` first (to find the bucket), then
`equals()` within the bucket. If two "equal" objects have different hash codes they land in
different buckets, so a lookup with an equal-but-different instance **fails to find** the
entry — e.g. `set.contains(new Point(1,1))` returns `false` even though an equal point was
added. Overriding both keeps them consistent.

### Part C — reference solutions

**C1.**
```java
public class BankAccount {
    private double balance;
    public BankAccount(double initial) {
        if (initial < 0) throw new IllegalArgumentException("initial < 0");
        balance = initial;
    }
    public void deposit(double amount) {
        if (amount <= 0) throw new IllegalArgumentException("amount <= 0");
        balance += amount;
    }
    public void withdraw(double amount) {
        if (amount <= 0) throw new IllegalArgumentException("amount <= 0");
        if (amount > balance) throw new IllegalArgumentException("overdraw");
        balance -= amount;
    }
    public double getBalance() { return balance; }
}
```
```java
import static org.junit.jupiter.api.Assertions.*;
import org.junit.jupiter.api.Test;

class BankAccountTest {
    @Test void normalFlow() {
        BankAccount a = new BankAccount(100);
        a.deposit(50);
        a.withdraw(30);
        assertEquals(120.0, a.getBalance(), 1e-9);
    }
    @Test void overdrawThrows() {
        BankAccount a = new BankAccount(10);
        assertThrows(IllegalArgumentException.class, () -> a.withdraw(20));
    }
}
```

**C2.**
```java
abstract class Shape {
    abstract double area();
    String describe() { return "Shape with area " + area(); }
}
class Circle extends Shape {
    private final double r;
    Circle(double r) { this.r = r; }
    double area() { return Math.PI * r * r; }
}
class Rectangle extends Shape {
    private final double w, h;
    Rectangle(double w, double h) { this.w = w; this.h = h; }
    double area() { return w * h; }
}

static double totalArea(java.util.List<Shape> shapes) {
    double sum = 0;
    for (Shape s : shapes) sum += s.area();   // polymorphic call
    return sum;
}
```

**C3.**
```java
public static <T> java.util.Map<T, Integer> frequencies(java.util.List<T> items) {
    java.util.Map<T, Integer> freq = new java.util.HashMap<>();
    for (T item : items) freq.merge(item, 1, Integer::sum);
    return freq;
}
```
Calling with `List.of("a","b","a","c","a","b")` yields (order not guaranteed in a HashMap):
`{a=3, b=2, c=1}`.

**C4.**
```java
interface Discount { double apply(double price); }

class NoDiscount implements Discount {
    public double apply(double price) { return price; }
}
class PercentOff implements Discount {
    private final double pct;
    PercentOff(double pct) { this.pct = pct; }
    public double apply(double price) { return price * (1 - pct / 100.0); }
}

static double checkout(double price, Discount d) { return d.apply(price); }

// Examples:
//   checkout(100, new NoDiscount())      -> 100.0
//   checkout(100, new PercentOff(20))    ->  80.0
```

---

*End of practice exam. These are original study questions in the CSE1100 style — not real
past-exam content. For official past exams, use the TU Delft course/Brightspace resources.*

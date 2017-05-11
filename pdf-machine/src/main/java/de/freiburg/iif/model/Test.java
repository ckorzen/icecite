package de.freiburg.iif.model;

public class Test {
  static String s = "Hello";
  static String[] o = {"Hello", "Huhu"};
  static Object p = o;
  
  public static void main(String[] args) {
    System.out.println(p instanceof String);
    System.out.println(p instanceof String[]);
    System.out.println(p instanceof Object);
    System.out.println(p instanceof Object[]);
  }
}

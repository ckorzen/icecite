//package list;
//
//import java.util.Comparator;
//
//import de.freiburg.iif.model.HasRectangle;
//
//public interface PrimitiveList {
//  /**
//   * Returns the index at position i.
//   * 
//   * @param i the position.
//   * 
//   * @return the index at position i.
//   */
//  public int getIndex(int i);
//  
//  /**
//   * Returns the element at position i.
//   * 
//   * @param i the index.
//   * 
//   * @return the element at position i.
//   */
//  public HasRectangle getElement(int i);
//
//  /**
//   * Adds the given element to this list.
//   * 
//   * @param element the element to add.
//   */
//  public <T extends HasRectangle> void add(T element);
//  
//  /**
//   * Swaps the elements at position i and j.
//   * 
//   * @param i the first position.
//   * @param j the second position.
//   */
//  public void swap(int i, int j);
//    
//  /**
//   * Sorts this list using the given Comparator.
//   */
//  public void sortByMinX();
//  
//  public void sortByMinY();
//  
//  /**
//   * Returns the size of this list.
//   * 
//   * @return the size of this list.
//   */
//  public int size();
//  
//  /**
//   * Returns a sublist of this list.
//   * 
//   * @param i the start index of sublist.
//   * @param j the end index of sublist.
//   * 
//   * @return a sublist of this list.
//   */
//  public PrimitiveList subList(int i, int j);
//}

package xy;

import java.util.ArrayList;
import java.util.List;

import de.freiburg.iif.model.HasRectangle;
import gnu.trove.TIntCollection;
import gnu.trove.list.linked.TIntLinkedList;
import icecite.models.HasRectangleList;

/**
 * An abstract class to cut a list of rectangles into blocks.
 * 
 * @author Claudius Korzen
 */
public abstract class XYCut<S extends HasRectangle, T extends HasRectangleList<S>> {    
  /**
   * Cuts the given list of elements into blocks.
   * 
   * @param elements the elements to cut. 
   * 
   * @return list of list of elements, where each inner list represents a block
   * resulted from cutting.
   */
  public List<T> cut(HasRectangleList<S> elements) {    
    List<T> result = new ArrayList<>();
    cut(elements, result);
    return result;  
  }

  /**
   * Cuts the given elements into blocks and adds them to the given result 
   * list.
   * 
   * @param elements the elements to cut.
   * @param res the result list.
   */
  protected void cut(HasRectangleList<S> elements, List<T> result) {
    // Cut vertically. Returns a list of sublists of the elements.
    List<HasRectangleList<S>> vBlocks = cutVertically(elements);
    
    for (HasRectangleList<S> vBlock : vBlocks) {
      // Cut horizontally. Returns a list of sublists of the elements.  
      List<HasRectangleList<S>> hBlocks = cutHorizontally(vBlock);
      
      if (hBlocks.size() == 1) {
        // The elements could not cut. A final block was found. 
        result.add(wrap(hBlocks.get(0)));
      } else {
        for (HasRectangleList<S> hBlock : hBlocks) {
          cut(hBlock, result);
        }
      }
    }
  }

  /**
   * Sweeps the given elements from left to right and tries to split them 
   * vertically. Returns a list of sublists of given elements, representing
   * the separated elements.
   * 
   * @param elements the elements to cut.
   * 
   * @return A list of sublists of given elements
   */
  protected List<HasRectangleList<S>> cutVertically(HasRectangleList<S> elements) {
    float laneWidth = getVerticalLaneWidth(elements);
    
    // Sort the elements by minX (ascending).
    elements.sortByMinX(false);
        
    // Initialize a priority queue for the elements overlapped by the lane.
    TIntLinkedList queue = new TIntLinkedList();

    // Add the first element to pq.
    queue.add(0);

    List<HasRectangleList<S>> result = new ArrayList<>();
    for (int i = 1; i < elements.size(); i++) {
      float rightBoundary = elements.getMinX(i);

      // Remove all elements from pq which doesn't...
      while (!queue.isEmpty()) {
        float leftBoundary = elements.getMaxX(queue.get(0));
        if (rightBoundary - leftBoundary < laneWidth) {
          break;
        }
        queue.removeAt(0);
      }
            
      if (isValidVerticalLane(elements, rightBoundary - laneWidth, rightBoundary, queue)) {
        result.add(elements.subList(0, i));
        result.add(elements.subList(i, elements.size()));
        return result;
      }
      queue.add(i);
    }

    result.add(elements);
    return result;
  }

  /**
   * Sweeps the given elements from top to bottom and tries to split them 
   * horizontally. Returns a list of sublists of given elements, representing
   * the separated elements.
   * 
   * @param elements the elements to cut.
   * 
   * @return A list of sublists of given elements
   */
  protected List<HasRectangleList<S>> cutHorizontally(HasRectangleList<S> elements) {
    float laneHeight = getHorizontalLaneHeight(elements);
    
    // Sort the elements by minY (decending).
    elements.sortByMinY(true);
        
    // Put the elements into an priorityQueue.
    TIntLinkedList queue = new TIntLinkedList();

    // Add the first element to pq.
    queue.add(0);

    List<HasRectangleList<S>> result = new ArrayList<>();
    for (int i = 1; i < elements.size(); i++) {
      float lowerBorder = elements.getMaxY(i);

      // Remove all elements from pq which doesn't...
      while (!queue.isEmpty()) {
        float upperBorder = elements.getMinY(queue.get(0));
        if (upperBorder - lowerBorder < laneHeight) {
          break;
        }
        queue.removeAt(0);
      }

      if (isValidHorizontalLane(elements, lowerBorder, lowerBorder + laneHeight, queue)) {
        result.add(elements.subList(0, i));
        result.add(elements.subList(i, elements.size()));
        return result;
      }
      queue.add(i);
    }

    result.add(elements);
    return result;
  }

  /**
   * Returns the width of the vertical lane to sweep through the given elements.
   * 
   * @param elements the elements to sweep.
   * 
   * @return the width of the vertical lane to sweep.
   */
  public abstract float getVerticalLaneWidth(HasRectangleList<S> elements);

  /**
   * Returns the height of the vertical lane to sweep through the given
   * elements.
   * 
   * @param elements the elements to sweep.
   * 
   * @return the height of the vertical lane to sweep.
   */
  public abstract float getHorizontalLaneHeight(HasRectangleList<S> elements);

  /**
   * Returns true, if the vertical lane that overlaps the given elements is
   * valid; false otherwise.
   * 
   * @param elements the elements to cut.
   * @param leftBoundary the left boundary of the lane.
   * @param rightBoundary the right boundary of the lane.
   * @param indexes the indexes of elements overlapping the lane.
   * 
   * @return true, if the lane that overlaps the given elements is valid; false
   * otherwise.
   */
  public abstract boolean isValidVerticalLane(HasRectangleList<S> elements, 
      float leftBoundary, float rightBoundary, TIntCollection indexes);
  
  /**
   * Returns true, if the horizontal lane that overlaps the given elements is 
   * valid; false otherwise.
   * 
   * @param elements the elements to cut.
   * @param lowerBoundary the lower boundary of the lane.
   * @param upperBoundary the upper boundary of the lane.
   * @param indexes the indexes of elements overlapping the lane.
   * 
   * @return true, if the lane that overlaps the given elements is valid; false
   * otherwise.
   */
  public abstract boolean isValidHorizontalLane(HasRectangleList<S> elements, 
      float lowerBoundary, float upperBoundary, TIntCollection indexes);
  
  /**
   * Casts the given elements to the target type.
   *  
   * @param elements the elements to cast.
   * 
   * @return an object of given target type.
   */
  public abstract T wrap(HasRectangleList<S> elements);
}
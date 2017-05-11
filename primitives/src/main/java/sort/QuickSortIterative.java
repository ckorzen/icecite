//package sort;
//
//import java.util.Comparator;
//
//import list.PrimitiveList;
//
//public class QuickSortIterative {
//  
//  public static <T> void sort(PrimitiveList<T> arr, Comparator<T> c) {
//    if (arr == null) {
//      return;
//    }
//    
//    if (arr.size() < 2) {
//      return;
//    }
//    
//    sort(arr, c, 0, arr.size() - 1);
//  }
//  
//  public static <T> void sort(PrimitiveList<T> arr, Comparator<T> c, int l, int h) {
//    // create auxiliary stack
//    int[] stack = new int[h - l + 1];
//
//    // initialize top of stack
//    int top = -1;
//
//    // push initial values in the stack
//    stack[++top] = l;
//    stack[++top] = h;
//
//    // keep popping elements until stack is not empty
//    while (top >= 0) {
//      // pop h and l
//      h = stack[top--];
//      l = stack[top--];
//
//      // set pivot element at it's proper position
//      int p = partition(arr, c, l, h);
//
//      // If there are elements on left side of pivot,
//      // then push left side to stack
//      if (p - 1 > l) {
//        stack[++top] = l;
//        stack[++top] = p - 1;
//      }
//
//      // If there are elements on right side of pivot,
//      // then push right side to stack
//      if (p + 1 < h) {
//        stack[++top] = p + 1;
//        stack[++top] = h;
//      }
//    }
//  }
//
//  /* This function is same in both iterative and
//       recursive*/
//  static <T> int partition(PrimitiveList<T> arr, Comparator<T> c, int l, int h) {
//    T x = arr.getElement(l + (h - l) / 2);
//    int i = (l - 1);
//
//    for (int j = l; j <= h - 1; j++) {
//      if (c.compare(arr.getElement(j), x) <= 0) {
//        i++;
//        // swap arr[i] and arr[j]
//        arr.swap(i, j);
//      }
//    }
//    // swap arr[i+1] and arr[h]
//    arr.swap(i + 1, h);
//    return (i + 1);
//  }
//}
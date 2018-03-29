package de.freiburg.iif.model;

import java.io.IOException;
import java.util.List;
import java.util.Random;

import org.apache.pdfbox.cos.COSDictionary;
import org.apache.pdfbox.cos.COSName;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.interactive.action.type.PDActionJavaScript;
import org.apache.pdfbox.pdmodel.interactive.form.PDAcroForm;
import org.apache.pdfbox.pdmodel.interactive.form.PDField;

import de.freiburg.iif.enrichment.CitationsDetector.Citation;

/** 
 * A class representing a popup in pdf, displaying the metadata of associated
 * citation.
 * 
 * @author Claudius Korzen
 */
public class PDPopupNew {
  protected PDDocument doc;
  // The background color.
  protected static final float[] backgroundColor = { 0.8f, 0.8f, 0.8f };
  // The border color.
  protected static final float[] borderColor = { 0.2f, 0.2f, 0.2f };
  // The id.
  public int id;
  // The acro form.
  protected PDAcroForm form;
  // The acro form.
  @SuppressWarnings("rawtypes")
  protected List pages;
  // The container.
  protected PDField container;
  // The title.
  protected PDField title;
  // The authors.
  protected PDField authors;
  // The metadata.
  protected PDField metadata;
  // The metadata.
  public PDField importBtn;
  // The metadata.
  public PDField closeBtn;
  // The citation button.
  public PDField citationButton;
  // The previous reveal action.
  private COSDictionary prevRevealAction;
  // The previous hide action.
  private COSDictionary prevHideAction;
  
  /**
   * The private constructor.
   */
  private PDPopupNew(PDDocument doc, PDAcroForm form) {
    this.doc = doc;
    this.pages = doc.getDocumentCatalog().getAllPages();
    this.id = new Random().nextInt(100000);
    this.form = form;
  }
    
  /**
   * Creates the popup for given CitationPosition.
   */
  public static PDPopupNew create(PDDocument doc, PDAcroForm form, Citation pos) throws IOException {
    PDPopupNew popup = new PDPopupNew(doc, form);
    popup.createCitationButton(pos);
//    popup.createPopup(pos);
//    popup.link();
    return popup;
  }
        
  /**
   * Creates the popup on given page in given position. 
   */
  protected void createPopup(Citation citation) throws IOException {
    PDRectangle popupPos = getPopupPosition(citation);
    container = createContainer(citation, popupPos);
    title = initTitle(citation, getTitlePosition(popupPos));
    authors = initAuthors(citation, getAuthorsPosition(popupPos));
    metadata = initMetadata(citation, getMetadataPosition(popupPos));
    closeBtn = initCloseButton(citation, getCloseButtonPosition(popupPos));
    importBtn = initImportButton(citation, getImportButtonPosition(popupPos));
  }
  
  /**
   * Links the citation button and the popup, i.e. adds the reveal action to
   * citation button and the hide action to close button.
   */
  protected void link() {
    COSDictionary actions = new COSDictionary();
    // Define action on entering the field with mouse.
    actions.setItem(COSName.U, prevRevealAction);
    citationButton.getDictionary().setItem(COSName.AA, actions);
    
    actions = new COSDictionary();
    // Define action on entering the field with mouse.
    actions.setItem(COSName.U, prevHideAction);
    closeBtn.getDictionary().setItem(COSName.AA, actions);
  }
  
  // ___________________________________________________________________________
  
  /**
   * Creates the citation button.
   */
  private void createCitationButton(Citation pos) throws IOException {      
    PDPage page = getPage(pos.page);
    
    PDButton button = new PDButton(form);
    PDRectangle rect = convertPositions(pos.rectangle, page);
    rect.setLowerLeftX(rect.getUpperRightX());
    rect.setLowerLeftY(rect.getUpperRightY() - 5);
    rect.setUpperRightX(rect.getLowerLeftX() + 5);
    rect.setUpperRightY(rect.getLowerLeftY() + 5);
    
    button.setRectangle(rect);
    button.setPage(page);
    button.setHidden(false);
    float[] bgColor = { .5f, 0f, 0f };
    button.setBackgroundColor(bgColor);    

//    citationButton = new PDButton(form, "citation-" + id, null, null, page, 
//        convertPositions(pos.rectangle, page), null, null, false);
    add(page, button);
  }
  
  /**
   * Creates the container field.
   */
  private PDField createContainer(Citation c, PDRectangle r) throws IOException {
    PDPage page = getPage(c.page);
    PDTextLabel field = new PDTextLabel(form, id + "-container", true, null, 
        null, page, r, backgroundColor, borderColor);
    add(page, field);
    addToRevealAction(field.getId());
    addToHideAction(field.getId());
    return field;
  }
      
  /**
   * Creates the title field.
   */
  private PDField initTitle(Citation cit, PDRectangle pos) throws IOException {
    PDPage page = getPage(cit.page);
    
    HasMetadata entry = cit.entry;
    String title = entry.getTitle() != null ? entry.getTitle() : entry.getRaw();
    String font = entry.getTitle() != null ? "/TiBo 12 Tf 0 0.2 0.4 rg" : "/TiIt 12 Tf 0.2 0.2 0.2 rg";
    PDTextLabel title1 = new PDTextLabel(form, id + "-title1", true, title, font, page, pos, backgroundColor, null);
    PDTextLabel title2 = new PDTextLabel(form, id + "-title2", true, title, font, page, pos, backgroundColor, null);
    title2.setReadOnly();
    System.out.println("XXX");
    add(page, title1);
    addToRevealAction(title1.getId());
    addToHideAction(title1.getId());
    add(page, title2);
    addToRevealAction(title2.getId());
    addToHideAction(title2.getId());
    return title1;
  }
  
  /**
   * Creates the authors field.
   */
  private PDField initAuthors(Citation citation, PDRectangle pos) 
      throws IOException {  
    PDPage page = getPage(citation.page);
    HasMetadata hm = citation.entry;
    String authors = hm.getAuthors() != null ? stringify(hm.getAuthors()) : "";
    PDTextLabel field = new PDTextLabel(form, id + "-authors", true, authors,
       "/TiIt 10 Tf 0.2 0.2 0.2 rg", page, pos, backgroundColor, null);
    add(page, field);
    addToRevealAction(field.getId());
    addToHideAction(field.getId());
    return field;
  }
  
  /**
   * Creates the metadata field.
   */
  private PDField initMetadata(Citation citation, PDRectangle pos)
      throws IOException {    
    PDPage page = getPage(citation.page);
    HasMetadata hm = citation.entry;
    String metadata = hm.getJournal() != null ? 
        (hm.getJournal()  + ", " + hm.getYear()) : "";
    // Create the entry for other metadata.
    PDTextLabel field = new PDTextLabel(form, id + "-metadata", true, metadata, 
       "/TiRo 10 Tf 0.2 0.2 0.2 rg", page, pos, backgroundColor, null);
    add(page, field);
    addToRevealAction(field.getId());
    addToHideAction(field.getId());
    return field;
  }
  
  /**
   * Creates the import button.
   */
  private PDField initImportButton(Citation citation, PDRectangle pos)
      throws IOException {    
    PDPage page = getPage(citation.page);
    // Create the entry for other metadata.
    PDTextLabel field = new PDTextLabel(form, id + "-import", true,
      "Import Into Icecite", "/TiRo 8 Tf 0 0 1 rg", page, pos, 
      backgroundColor, null);
    add(page, field);
    addToRevealAction(field.getId());
    addToHideAction(field.getId());    
    
    PDButton importButton = new PDButton(form, id + "-import2", null, null, 
        page, pos, null, null, true);
    importButton.setAction(new PDActionJavaScript(
      "if (this.hostContainer) {" +
      "  this.hostContainer.postMessage(['import', '" + citation.entry.toJson() + "']);" +
      "}"));
    add(page, importButton);
    addToRevealAction(importButton.getId());
    addToHideAction(importButton.getId());
             
    return importButton;
  }
  
  /**
   * Creates the close button.
   */
  private PDField initCloseButton(Citation citation, PDRectangle pos)
      throws IOException {    
    PDPage page = getPage(citation.page);
    // Create the entry for other metadata.
    PDTextLabel field = new PDTextLabel(form, id + "-close1", true, "X",
        "/HeBo 5 Tf 0.2 0.2 0.2 rg", page, pos, backgroundColor, null);
    add(page, field);
    addToRevealAction(field.getId());
    addToHideAction(field.getId());
    
    PDButton closeButton = new PDButton(form, id + "-close2", null, null, 
        page, pos, null, null, true);
    add(page, closeButton);
    addToRevealAction(closeButton.getId());
    addToHideAction(closeButton.getId());
             
    return closeButton;
  }
  
  // ___________________________________________________________________________
  
  /**
   * Adds the given field to given page.
   */
  @SuppressWarnings("unchecked")
  private PDField add(PDPage page, PDField field) throws IOException {
    page.getAnnotations().add(field.getWidget());
    form.getFields().add(field);
    return field;
  }
    
  /**
   * Adds the given id to reveal action.
   */
  private void addToRevealAction(String id) {
    COSDictionary revealAction = new COSDictionary();
    revealAction.setName(COSName.S, "Hide");
    revealAction.setString(COSName.T, id);
    revealAction.setBoolean(COSName.H, false);
    if (prevRevealAction != null) {
      revealAction.setItem(COSName.NEXT, prevRevealAction);
    }
    prevRevealAction = revealAction;
  }
  
  /**
   * Adds the given id to hide action.
   */
  private void addToHideAction(String id) {
    COSDictionary hideAction = new COSDictionary();
    hideAction.setName(COSName.S, "Hide");
    hideAction.setString(COSName.T, id);
    if (prevHideAction != null) {
      hideAction.setItem(COSName.NEXT, prevHideAction);
    }
    prevHideAction = hideAction;
  }
  
  // ___________________________________________________________________________
  
  /**
   * Computes the position for popup. The method will check, if there is enough
   * space for the popup above the citation. If necessary, the position popup is
   * moved to the right, to the left or to the bottom of citation.
   * 
   * @param rect the position of cittion button.
   * @param page the page, where the popup should be located.
   * @return the position of popup.
   */
  private PDRectangle getPopupPosition(Citation pos) {
    float popupWidth = 400;
    float popupHeight = 100;
    float vertDistCitationPopup = 5;
    
    PDRectangle rect = convertPositions(pos.rectangle, getPage(pos.page));
        
    // Get the page dimensions.
    PDRectangle pageRect = getPageRect(getPage(pos.page));
    float pageUpperBorder = pageRect.getUpperRightY();
    float pageLeftBorder = pageRect.getLowerLeftX();
    float pageRightBorder = pageRect.getUpperRightX();
    
    // Compute the position of the left border of popup.
    float citationMidpoint = rect.getLowerLeftX() + 
        (rect.getUpperRightX() - rect.getLowerLeftX()) / 2;
    float popupLeftBorder = citationMidpoint - (popupWidth / 2);
    float popupRightBorder = popupLeftBorder + popupWidth;
    
    if (popupLeftBorder < pageLeftBorder) {
      popupLeftBorder = pageLeftBorder;
      popupRightBorder = popupLeftBorder + popupWidth;
    }
    
    // Compute the position of the right border of popup.
    if (popupRightBorder > pageRightBorder) {
      popupRightBorder = pageRightBorder;
      popupLeftBorder = popupRightBorder - popupWidth;
    }
    
    // Compute the position of the upper border of popup
    float citationUpperBorder = rect.getUpperRightY();
    float popupLowerBorder = citationUpperBorder + vertDistCitationPopup;
    float popupUpperBorder = popupLowerBorder + popupHeight;
    if (popupUpperBorder > pageUpperBorder) {
      // There isn't enough space above the citation, so place the popup below
      // the citation.
      float citationLowerBorder = rect.getLowerLeftY();
      popupUpperBorder = citationLowerBorder - vertDistCitationPopup;
      popupLowerBorder = popupUpperBorder - popupHeight;
    }
        
    PDRectangle popupRect = new PDRectangle();  
    popupRect.setLowerLeftX(popupLeftBorder);
    popupRect.setLowerLeftY(popupLowerBorder);
    popupRect.setUpperRightX(popupRightBorder);
    popupRect.setUpperRightY(popupUpperBorder);
    return popupRect;
  }
  
  /**
   * Computes the position of title in popup.
   * 
   * @param pRect the bounding box of popup.
   * @return the bounding box of title.
   */
  protected PDRectangle getTitlePosition(PDRectangle pRect) {
    PDRectangle rect = new PDRectangle();
    rect.setLowerLeftX(pRect.getLowerLeftX() + 5);
    rect.setLowerLeftY(pRect.getUpperRightY() - 0.4f * pRect.getHeight());
    rect.setUpperRightX(pRect.getUpperRightX() - 5);
    rect.setUpperRightY(pRect.getUpperRightY() - 5);
    return rect;
  }
  
  /**
   * Computes the position of authors in popup.
   */
  protected PDRectangle getAuthorsPosition(PDRectangle pRect) {
    PDRectangle rect = new PDRectangle();
    rect.setLowerLeftX(pRect.getLowerLeftX() + 5);
    rect.setLowerLeftY(pRect.getUpperRightY() - 0.6f * pRect.getHeight());
    rect.setUpperRightX(pRect.getUpperRightX() - 5);
    rect.setUpperRightY(pRect.getUpperRightY() - 0.4f * pRect.getHeight());
    return rect;
  }
  
  /**
   * Computes the position of metadata in popup.
   */
  protected PDRectangle getMetadataPosition(PDRectangle pRect) {
    PDRectangle rect = new PDRectangle();
    rect.setLowerLeftX(pRect.getLowerLeftX() + 5);
    rect.setLowerLeftY(pRect.getUpperRightY() - 0.8f * pRect.getHeight());
    rect.setUpperRightX(pRect.getUpperRightX() - 5);
    rect.setUpperRightY(pRect.getUpperRightY() - 0.6f * pRect.getHeight());
    return rect;
  }
  
  /**
   * Computes the position of the import button in popup.
   */
  protected PDRectangle getImportButtonPosition(PDRectangle pRect) {
    PDRectangle rect = new PDRectangle();
    rect.setLowerLeftX(pRect.getLowerLeftX() + 5);
    rect.setLowerLeftY(pRect.getUpperRightY() - pRect.getHeight() + 5);
    rect.setUpperRightX(pRect.getUpperRightX() - 5);
    rect.setUpperRightY(pRect.getUpperRightY() - 0.8f * pRect.getHeight());
    return rect;
  }
  
  /**
   * Computes the position of close button in popup.
   */
  protected PDRectangle getCloseButtonPosition(PDRectangle popupRect) {
    PDRectangle rect = new PDRectangle();
    rect.setLowerLeftX(popupRect.getUpperRightX() - 12);
    rect.setLowerLeftY(popupRect.getUpperRightY() - 12);
    rect.setUpperRightX(popupRect.getUpperRightX() - 2);
    rect.setUpperRightY(popupRect.getUpperRightY() - 2);
    return rect;
  }
  
  /**
   * Converts the position of text, such that (0,0) is the lower left.
   */
  protected PDRectangle convertPositions(PDRectangle rect, PDPage page) {
    PDRectangle pageRect = getPageRect(page);
        
    if (pageRect != null) {
      float pageHeight = Math.abs(pageRect.getLowerLeftY() - 
          pageRect.getUpperRightY());
      
      PDRectangle converted = new PDRectangle();
      converted.setLowerLeftX(rect.getLowerLeftX());
      converted.setLowerLeftY(Math.abs(rect.getLowerLeftY() - pageHeight));
      converted.setUpperRightX(rect.getUpperRightX());
      converted.setUpperRightY(Math.abs(rect.getUpperRightY() - pageHeight));
      
      return converted;
    }
    return null;
  }
  
  /** Stringifies the given list */
  protected String stringify(List<?> list) {
    StringBuilder sb = new StringBuilder();
    for (int i = 0; i < list.size(); i++) {
      Object object = list.get(i);
      if (object != null) sb.append(object);
      sb.append(i < list.size() - 1 ? ", " : "");
    }
    return sb.toString();
  }
  
  /** Determines the bounding box of given page */
  protected PDRectangle getPageRect(PDPage page) {
    PDRectangle pageRect = page.getMediaBox();
    if (pageRect == null) pageRect = page.getCropBox();
    if (pageRect == null) pageRect = page.getBleedBox();
    if (pageRect == null) pageRect = page.getArtBox();
    if (pageRect == null) pageRect = new PDRectangle(612, 792);
    return pageRect;
  }
  
  private PDPage getPage(int page) {
    return (PDPage) pages.get(page);
  }
}

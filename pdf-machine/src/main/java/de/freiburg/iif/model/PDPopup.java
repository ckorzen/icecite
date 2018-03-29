package de.freiburg.iif.model;

import java.awt.Color;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

import org.apache.pdfbox.cos.COSDictionary;
import org.apache.pdfbox.cos.COSName;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.edit.PDPageContentStream;
import org.apache.pdfbox.pdmodel.font.PDFont;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
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
public class PDPopup {
  static final float CITATION_BUTTON_WIDTH = 6;
  static final float CITATION_BUTTON_HEIGHT = 6;
  static final Color CITATION_BUTTON_BACKGROUND_COLOR = Color.BLUE;
  static final Color CITATION_BUTTON_TEXT_COLOR = Color.WHITE;
  static final PDFont CITATION_BUTTON_FONT = PDType1Font.TIMES_ROMAN;
  static final float CITATION_BUTTON_FONT_SIZE = CITATION_BUTTON_WIDTH;
  static final char CITATION_BUTTON_CHAR = 'i';
  static final float DEATH_ZONE_WIDTH = 30;
  // The background color of popup.
  protected static final float[] POPUP_BACKGROUND_COLOR = { 0.8f, 0.8f, 0.8f };
  // The border color of popup.
  protected static final float[] POPUP_BORDER_COLOR = { 0.2f, 0.2f, 0.2f };

  // The acro form.
  protected PDAcroForm form;
  // The document to process.
  protected PDDocument doc;
  // The acro form.
  @SuppressWarnings("rawtypes")
  protected List pages;
  // The id.
  public int id;
  // The citation button.
  public PDField citationButton;
  // The previous reveal action.
  private COSDictionary prevRevealAction;
  // The previous hide action.
  private COSDictionary prevHideAction;
  // The fields of hide area
  private List<PDField> deathZone;
  
  /**
   * The private constructor.
   */
  private PDPopup(PDDocument doc, PDAcroForm form) {
    this.deathZone = new ArrayList<PDField>();
    this.pages = doc.getDocumentCatalog().getAllPages();
    this.id = new Random().nextInt(100000);
    this.form = form;
    this.doc = doc;
  }
    
  /**
   * Creates the popup for given CitationPosition.
   */
  public static PDPopup create(PDDocument doc, PDAcroForm form, 
    Citation citation) throws IOException {
    PDPopup popup = new PDPopup(doc, form);
    popup.createCitationButton(citation);
    popup.createDeathZone(citation);
    popup.createPopup(citation);
    popup.link();
    return popup;
  }
  
  // ___________________________________________________________________________
  
  /**
   * Creates the citation button.
   */
  private void createCitationButton(Citation citation) throws IOException {      
    PDPage page = getPage(citation.page);
    PDRectangle rect = getCitationButtonPosition(citation);
    PDPageContentStream stream = 
        new PDPageContentStream(doc, page, true, true, true);
            
    // Draw a rectangle.
    stream.setNonStrokingColor(CITATION_BUTTON_BACKGROUND_COLOR);
    stream.fillRect(rect.getLowerLeftX(), rect.getLowerLeftY(), 
                    rect.getWidth(), rect.getHeight());
    
    /// Draw a text into the rectangle.
    float textXAmount = rect.getLowerLeftX() + CITATION_BUTTON_WIDTH / 3f;
    float textYAmount = rect.getLowerLeftY() + CITATION_BUTTON_HEIGHT / 6f;
    stream.setNonStrokingColor(CITATION_BUTTON_TEXT_COLOR);
    stream.beginText();
    stream.setFont(CITATION_BUTTON_FONT, CITATION_BUTTON_FONT_SIZE);    
    stream.moveTextPositionByAmount(textXAmount, textYAmount);
    stream.drawString(String.valueOf(CITATION_BUTTON_CHAR));
    stream.endText();
    stream.close();
    
    /// Create citation button.
    PDButton citationButton = new PDButton(form);
    citationButton.setId("citation-" + id);
    citationButton.setPage(page);
    citationButton.setRectangle(rect);
    citationButton.setHidden(false);
    
    add(page, citationButton);
    this.citationButton = citationButton;
  }
  
  /**
   * Creates the death zone.
   */
  private void createDeathZone(Citation citation) throws IOException {
    PDPage page = getPage(citation.page);
    PDRectangle buttonPos = getCitationButtonPosition(citation);
    PDRectangle pos = getPopupPosition(citation);
        
    float leftX = Math.min(buttonPos.getLowerLeftX(), pos.getLowerLeftX());
    float leftY = Math.min(buttonPos.getLowerLeftY(), pos.getLowerLeftY());
    float rightX = Math.max(buttonPos.getUpperRightX(), pos.getUpperRightX());
    float rightY = Math.max(buttonPos.getUpperRightY(), pos.getUpperRightY());
        
    PDRectangle rect1 = new PDRectangle();
    rect1.setLowerLeftX(leftX - DEATH_ZONE_WIDTH);
    rect1.setLowerLeftY(leftY);
    rect1.setUpperRightX(leftX);
    rect1.setUpperRightY(rightY);
    createDeathField(id + "-death1", rect1, page);
        
    PDRectangle rect2 = new PDRectangle();
    rect2.setLowerLeftX(rightX);
    rect2.setLowerLeftY(leftY);
    rect2.setUpperRightX(rightX + DEATH_ZONE_WIDTH);
    rect2.setUpperRightY(rightY);
    createDeathField(id + "-death2", rect2, page);
        
    PDRectangle rect3 = new PDRectangle();
    rect3.setLowerLeftX(leftX - DEATH_ZONE_WIDTH);
    rect3.setLowerLeftY(leftY - DEATH_ZONE_WIDTH);
    rect3.setUpperRightX(rightX + DEATH_ZONE_WIDTH);
    rect3.setUpperRightY(leftY);
    createDeathField(id + "-death3", rect3, page);
        
    PDRectangle rect4 = new PDRectangle();
    rect4.setLowerLeftX(leftX - DEATH_ZONE_WIDTH);
    rect4.setLowerLeftY(rightY);
    rect4.setUpperRightX(rightX + DEATH_ZONE_WIDTH);
    rect4.setUpperRightY(rightY + DEATH_ZONE_WIDTH);
    createDeathField(id + "-death4", rect4, page);
  }
  
  /**
   * Creates a death field.
   */
  protected PDTextLabel createDeathField(String id, PDRectangle rect, 
    PDPage page) throws IOException {
    // Create death field.
    PDTextLabel deathField = new PDTextLabel(form);
    deathField.setId(id);
    deathField.setHidden(true);
    deathField.setPage(page);
    deathField.setRectangle(rect);
    
    // Add to actions.
    addToRevealAction(deathField.getId());
    addToHideAction(deathField.getId());
    add(page, deathField);
    deathZone.add(deathField);
    
    return deathField;
  }
  
  /**
   * Creates the popup on given page in given position. 
   */
  protected void createPopup(Citation citation) throws IOException {
    createPopupContainer(citation);
    createTitleField(citation);
    createAuthorsField(citation);
    createMetadataField(citation);
    createImportField(citation);
  }
  
  /**
   * Creates the popup container.
   */
  protected void createPopupContainer(Citation citation) throws IOException {
    PDRectangle popupPos = getPopupPosition(citation);
    PDPage page = getPage(citation.page);
    
    PDTextLabel container = new PDTextLabel(form);
    container.setId(id + "-container");
    container.setHidden(true);
    container.setPage(page);
    container.setRectangle(popupPos);
    container.setBackgroundColor(POPUP_BACKGROUND_COLOR);
    container.setBorderColor(POPUP_BORDER_COLOR);
    
    // Add the container.
    add(page, container);
    addToRevealAction(container.getId());
    addToHideAction(container.getId());
  }
      
  /**
   * Creates the title field.
   */
  protected void createTitleField(Citation citation) throws IOException {
    PDRectangle titlePos = getTitlePosition(citation);
    PDPage page = getPage(citation.page);
    HasMetadata entry = citation.entry;
    
    String value = null;
    String font = null;
    if (entry.getTitle() != null) {
      value = entry.getTitle();
      font = "/TiBo 12 Tf 0 0.2 0.4 rg";
    } else {
      value = entry.getRaw();
      font = "/TiIt 12 Tf 0.2 0.2 0.2 rg";
    }

    PDTextLabel titleField = new PDTextLabel(form);
    titleField.setId(id + "-title1");
    titleField.setHidden(true);
    titleField.setValue(value);
    titleField.setFontAppearance(font);
    titleField.setPage(page);
    titleField.setRectangle(titlePos);
    titleField.setBackgroundColor(POPUP_BACKGROUND_COLOR);
    
    add(page, titleField);
    addToRevealAction(titleField.getId());
    addToHideAction(titleField.getId());
  }
  
  /**
   * Creates the authors field.
   */
  protected void createAuthorsField(Citation citation) throws IOException {  
    PDRectangle authorsPos = getAuthorsPosition(citation);
    PDPage page = getPage(citation.page);
    HasMetadata entry = citation.entry;
        
    float numAuthors = 0;
    if (entry.getAuthors() != null) {
      numAuthors = entry.getAuthors().size();
    }
    
    if (numAuthors > 0) {
      // Calculate the available width for each author.
      float availableWidth = authorsPos.getWidth() / numAuthors;
      float authorFieldLeftX = authorsPos.getLowerLeftX();      
      PDFont font = PDType1Font.TIMES_ITALIC;
      int fontSize = 12;
      
      for (int i = 0; i < numAuthors; i++) {
        String author = entry.getAuthors().get(i);
        
        float requiredWidth = font.getStringWidth(author) / 1000 * fontSize;
        float authorFieldWidth = Math.min(availableWidth, requiredWidth);
        
        PDRectangle rect = new PDRectangle();
        rect.setLowerLeftX(authorFieldLeftX);
        rect.setLowerLeftY(authorsPos.getLowerLeftY());
        rect.setUpperRightX(authorFieldLeftX + authorFieldWidth);
        rect.setUpperRightY(authorsPos.getUpperRightY());
        
        authorFieldLeftX += authorFieldWidth;
        
        // Create the label.
        PDTextLabel field = new PDTextLabel(form);
        field.setId(id + "-author" + i);
        field.setHidden(true);
        field.setValue(author + (i < numAuthors - 1 ? "," : ""));
        field.setFontAppearance("/TiIt 10 Tf 0.2 0.2 0.2 rg");
        field.setPage(page);
        field.setRectangle(rect);
        field.setBackgroundColor(POPUP_BACKGROUND_COLOR);                        
        add(page, field);
        addToRevealAction(field.getId());
        addToHideAction(field.getId());
          
        // Create the button.
        PDButton button = new PDButton(form);
        button.setId(id + "-author" + i + "-2");
        button.setPage(page);
        button.setRectangle(rect);
        button.setHidden(true);

        COSDictionary uriAction = createDblpAuthorPageUriAction(author);
        button.getDictionary().setItem(COSName.AA, uriAction);
        
        add(page, button);
        addToRevealAction(button.getId());
        addToHideAction(button.getId());
      }
    }
  }
  
  /**
   * Creates the metadata field.
   */
  private void createMetadataField(Citation citation) throws IOException {    
    PDRectangle metadataPos = getMetadataPosition(citation);
    PDPage page = getPage(citation.page);
    HasMetadata entry = citation.entry;
    
    String metadata = "";
    if (entry.getJournal() != null) {
      metadata = entry.getJournal()  + ", " + entry.getYear();
    }
        
    // Create the entry for other metadata.
    PDTextLabel field = new PDTextLabel(form);
    field.setId(id + "-metadata");
    field.setHidden(true);
    field.setValue(metadata);
    field.setFontAppearance("/TiRo 10 Tf 0.2 0.2 0.2 rg");
    field.setPage(page);
    field.setRectangle(metadataPos);
    field.setBackgroundColor(POPUP_BACKGROUND_COLOR);
    
    add(page, field);
    addToRevealAction(field.getId());
    addToHideAction(field.getId());
  }
  
  /**
   * Creates the import button.
   */
  private void createImportField(Citation citation) throws IOException {    
    PDRectangle importPos = getImportButtonPosition(citation);
    PDPage page = getPage(citation.page);

    /// Create the label.
    PDTextLabel field = new PDTextLabel(form);
    field.setId(id + "-import");
    field.setHidden(true);
    field.setValue("Import Into Icecite");
    field.setFontAppearance("/TiRo 8 Tf 0 0 1 rg");
    field.setPage(page);
    field.setRectangle(importPos);
    field.setBackgroundColor(POPUP_BACKGROUND_COLOR);
    
    add(page, field);
    addToRevealAction(field.getId());
    addToHideAction(field.getId());    
    
    /// Create the button.
    PDButton button = new PDButton(form);
    button.setId(id + "-import2");
    button.setHidden(true);
    button.setPage(page);
    button.setRectangle(importPos);

    String json = citation.entry.toJson();
    button.setAction(new PDActionJavaScript(
      "if (this.hostContainer) {" +
      "  this.hostContainer.postMessage(['import', '" + json + "']);" +
      "}"));
    add(page, button);
    addToRevealAction(button.getId());
    addToHideAction(button.getId());
  }

  /**
   * Links the citation button and the popup, i.e. adds the reveal action to
   * citation button and the hide action to close button.
   */
  protected void link() {
    COSDictionary actions = new COSDictionary();
    // Define action on entering the field with mouse.
    // E: mouse enter
    // X: mouse exits
    // D: mouse pressed
    // U: mouse released.

    actions.setItem(COSName.E, prevRevealAction);
    // actions.setItem(COSName.getPDFName("X"), prevHideAction);
    citationButton.getDictionary().setItem(COSName.AA, actions);

    actions = new COSDictionary();
    // Define action on entering the death zone with mouse.
    actions.setItem(COSName.E, prevHideAction);

    for (PDField deathField : deathZone) {
      deathField.getDictionary().setItem(COSName.AA, actions);
    }
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
  
  protected PDRectangle getCitationButtonPosition(Citation citation) {
    PDRectangle pos = convertPositions(citation.rectangle);
    
    pos.setLowerLeftX(pos.getUpperRightX());
    pos.setLowerLeftY(pos.getLowerLeftY() + .5f * pos.getHeight());
    pos.setUpperRightX(pos.getLowerLeftX() + CITATION_BUTTON_WIDTH);
    pos.setUpperRightY(pos.getLowerLeftY() + CITATION_BUTTON_HEIGHT);
    
    return pos;
  }
  
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
    
    PDRectangle rect = getCitationButtonPosition(pos);
        
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
  protected PDRectangle getTitlePosition(Citation citation) {
    PDRectangle popupPos = getPopupPosition(citation);
    PDRectangle rect = new PDRectangle();
    rect.setLowerLeftX(popupPos.getLowerLeftX() + 5);
    rect.setLowerLeftY(popupPos.getUpperRightY() - 0.4f * popupPos.getHeight());
    rect.setUpperRightX(popupPos.getUpperRightX() - 5);
    rect.setUpperRightY(popupPos.getUpperRightY() - 5);
    return rect;
  }
  
  /**
   * Computes the position of authors in popup.
   */
  protected PDRectangle getAuthorsPosition(Citation citation) {
    PDRectangle popupPos = getPopupPosition(citation);
    PDRectangle rect = new PDRectangle();
    rect.setLowerLeftX(popupPos.getLowerLeftX() + 5);
    rect.setLowerLeftY(popupPos.getUpperRightY() - 0.6f * popupPos.getHeight());
    rect.setUpperRightX(popupPos.getUpperRightX() - 5);
    rect.setUpperRightY(popupPos.getUpperRightY() - 0.4f * popupPos.getHeight());
    return rect;
  }
  
  /**
   * Computes the position of metadata in popup.
   */
  protected PDRectangle getMetadataPosition(Citation citation) {
    PDRectangle popupPos = getPopupPosition(citation);
    PDRectangle rect = new PDRectangle();
    rect.setLowerLeftX(popupPos.getLowerLeftX() + 5);
    rect.setLowerLeftY(popupPos.getUpperRightY() - 0.8f * popupPos.getHeight());
    rect.setUpperRightX(popupPos.getUpperRightX() - 5);
    rect.setUpperRightY(popupPos.getUpperRightY() - 0.6f * popupPos.getHeight());
    return rect;
  }
  
  /**
   * Computes the position of the import button in popup.
   */
  protected PDRectangle getImportButtonPosition(Citation citation) {
    PDRectangle popupPos = getPopupPosition(citation);
    PDRectangle rect = new PDRectangle();
    rect.setLowerLeftX(popupPos.getLowerLeftX() + 5);
    rect.setLowerLeftY(popupPos.getUpperRightY() - popupPos.getHeight() + 5);
    rect.setUpperRightX(popupPos.getUpperRightX() - 5);
    rect.setUpperRightY(popupPos.getUpperRightY() - 0.8f * popupPos.getHeight());
    return rect;
  }
  
  // ___________________________________________________________________________
  
  /**
   * Converts the position of text, such that (0,0) is the lower left.
   */
  protected PDRectangle convertPositions(PDRectangle rect) {
    PDRectangle pageRect = getPageRect(getPage(0));
        
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
  
  protected COSDictionary createDblpAuthorPageUriAction(String author) {
    String[] split = author.split(" ");
    StringBuilder url = new StringBuilder("http://www.dblp.org/pers/hc/");
    int j;
    char c = '\0';
    for (j = split.length - 1; j >= 0; j--) {
      String last = split[j];
      c = last.toLowerCase().charAt(0);
      if (Character.isLetter(c)) break;
    }
    url.append(c);
    url.append("/");

    for (int k = j; k < split.length; k++) {
      url.append(split[k].replaceAll("\\.", "="));
      if (k != split.length - 1) url.append("_"); 
    }
    url.append(":");
    
    for (int k = 0; k < j; k++) {
      url.append(split[k].replaceAll("\\.", "="));
      if (k != j - 1) url.append("_"); 
    }
    url.append(".html");

    
    // Add uri action.
    COSDictionary uriAction = new COSDictionary();
    uriAction.setName(COSName.S, "URI");
    uriAction.setString(COSName.URI, url.toString());  
    COSDictionary action = new COSDictionary();
    action.setItem(COSName.U, uriAction);
    return action;
  }
}

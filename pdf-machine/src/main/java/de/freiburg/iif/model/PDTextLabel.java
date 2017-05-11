package de.freiburg.iif.model;

import java.io.IOException;

import org.apache.pdfbox.cos.COSArray;
import org.apache.pdfbox.cos.COSDictionary;
import org.apache.pdfbox.cos.COSFloat;
import org.apache.pdfbox.cos.COSName;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.interactive.form.PDAcroForm;
import org.apache.pdfbox.pdmodel.interactive.form.PDTextbox;

/**
 * Class representing a text label in pdf.
 * 
 * @author Claudius Korzen
 */
public class PDTextLabel extends PDTextbox {

  /**
   * The constructor.
   */
  public PDTextLabel(PDAcroForm theAcroForm) {
    super(theAcroForm, new COSDictionary());
    
    // Set the types.
    getDictionary().setName(COSName.TYPE, "Annot");
    getDictionary().setName(COSName.SUBTYPE, "Widget");
    getDictionary().setName(COSName.FT, "Tx");
    
    // Specify the justification. 0=left, 1=centered, 2.
    //  title.setQ(0); // /Q
  }
  
  /**
   * The constructor.
   */
  public PDTextLabel(PDAcroForm form, String id, boolean hidden, String value,
    String font, PDPage page, PDRectangle pos, float[] bgColor, 
    float[] borderColor) throws IOException {
    this(form);
    setId(id);
    setValue(value);
    setFontAppearance(font);
    setPage(page);
    setRectangle(pos);
    setBackgroundColor(bgColor);
    setBorderColor(borderColor);
    setHidden(hidden);
  }
  
  /**
   * Sets the rectangle of this text label.
   */
  public void setRectangle(PDRectangle rect) throws IOException {
    getWidget().setRectangle(rect);
  }
  
  /**
   * Sets the background color of this text label.
   */
  public void setBackgroundColor(float[] bgColor) {
    COSDictionary dict = 
        (COSDictionary) getDictionary().getItem(COSName.getPDFName("MK"));
    if (dict == null) { dict = new COSDictionary(); }
    
    // Set the background color.
    if (bgColor != null && bgColor.length > 2) {  
      COSArray bg = new COSArray();
      bg.add(new COSFloat(bgColor[0]));
      bg.add(new COSFloat(bgColor[1]));
      bg.add(new COSFloat(bgColor[2]));
      dict.setItem(COSName.getPDFName("BG"), bg);
    }
    getDictionary().setItem(COSName.getPDFName("MK"), dict);
  }
  
  /**
   * Sets the border color of this text label.
   */
  public void setBorderColor(float[] borderColor) {
    COSDictionary dict = 
        (COSDictionary) getDictionary().getItem(COSName.getPDFName("MK"));
    if (dict == null) dict = new COSDictionary();
    
    // Set the border color.
    if (borderColor != null && borderColor.length > 2) {
      COSArray bc = new COSArray();
      bc.add(new COSFloat(borderColor[0]));
      bc.add(new COSFloat(borderColor[1]));
      bc.add(new COSFloat(borderColor[2]));
      dict.setItem(COSName.getPDFName("BC"), bc);
    }
    getDictionary().setItem(COSName.getPDFName("MK"), dict);
  }
  
  /**
   * Sets the font appearance of this text label.
   */
  public void setFontAppearance(String font) {
    // Set the font (/TiBo is Times Bold, see 
    // http://www.pdflib.com/fileadmin/pdflib/pdf/Bibel/bibel_d_pdfmark_1x1.pdf)
    if (font != null) { getDictionary().setString(COSName.DA, font); }
  }
  
  /**
   * Sets the value of this text label.
   */
  public void setValue(String value) {
    // Set the value (V) and the default value (DV)
    if (value != null) { getDictionary().setString(COSName.DV, " " + value); }
    if (value != null) { getDictionary().setString(COSName.V, " " + value); }
  }
  
  /**
   * Sets the hidden flag of this text label.
   */
  public void setHidden(boolean hidden) throws IOException {
    // Hide the container per default (F).
    getWidget().setHidden(hidden);
  }
  
  /**
   * Sets the page of this text label.
   */
  public void setPage(PDPage page) throws IOException {
    // Set the surrounding page (P).
    getWidget().setPage(page);
  }
  
  /**
   * Sets the id of this text label.
   */
  public void setId(String id) {
    getDictionary().setString(COSName.T, id);
  }
  
  /**
   * Returns the id of this text label.
   */
  public String getId() {
    return getDictionary().getString(COSName.T);
  }
  
  public void setReadOnly() {
    // Specify the type of textbox (first bit = read only).
    getDictionary().setInt(COSName.FF, 4097); // /Ff
  }
}

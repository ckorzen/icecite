package de.freiburg.iif.model;

import java.io.IOException;

import org.apache.pdfbox.cos.COSArray;
import org.apache.pdfbox.cos.COSDictionary;
import org.apache.pdfbox.cos.COSFloat;
import org.apache.pdfbox.cos.COSName;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.interactive.action.type.PDAction;
import org.apache.pdfbox.pdmodel.interactive.form.PDAcroForm;
import org.apache.pdfbox.pdmodel.interactive.form.PDPushButton;

public class PDButton extends PDPushButton {

  public PDButton(PDAcroForm theAcroForm) {
    super(theAcroForm, new COSDictionary());
    
    // Set the types.
    getDictionary().setName(COSName.TYPE, "Annot");
    getDictionary().setName(COSName.SUBTYPE, "Widget");
    getDictionary().setName(COSName.FT, "Btn"); // type of field.
    getDictionary().setInt(COSName.FF, 65536); // field flag, 16-bit: 1st bit: read only. 2nd bit: required. 3rd bit: No Export.
    getDictionary().setName(COSName.H, "N");
    // Specify the justification. 0=left, 1=centered, 2.
    //  title.setQ(0); // /Q
  }
  
  public PDButton(PDAcroForm form, String id, String value, String font, 
    PDPage page, PDRectangle pos, float[] bgColor, float[] borderColor,
    boolean hidden) throws IOException {
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
  
  public void setRectangle(PDRectangle rect) throws IOException {
    getWidget().setRectangle(rect);
  }
  
  public void setBackgroundColor(float[] bgColor) {
    COSDictionary dict = (COSDictionary) getDictionary().getItem(COSName.getPDFName("MK"));
    if (dict == null) dict = new COSDictionary();
    
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
  
  public void setBorderColor(float[] borderColor) {
    COSDictionary dict = (COSDictionary) getDictionary().getItem(COSName.getPDFName("MK"));
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
  
  public void setFontAppearance(String font) {
    // Set the font (/TiBo is Times Bold, see 
    // http://www.pdflib.com/fileadmin/pdflib/pdf/Bibel/bibel_d_pdfmark_1x1.pdf)
    if (font != null) getDictionary().setString(COSName.DA, font);
  }
  
  public void setValue(String value) {
    if (value != null) {
      // Set the value of the button.
      COSDictionary ca = new COSDictionary();
      ca.setString(COSName.CA, value);
      getDictionary().setItem(COSName.getPDFName("MK"), ca);
    }
  }
  
  public void setHidden(boolean hidden) throws IOException {
    // Hide the container per default (F).
    getWidget().setHidden(hidden);
  }
  
  public void setPage(PDPage page) throws IOException {
    // Set the surrounding page (P).
    getWidget().setPage(page);
  }
  
  public void setId(String id) {
    getDictionary().setString(COSName.T, id);
  }
  
  public String getId() {
    return getDictionary().getString(COSName.T);
  }
  
  public void setAction(PDAction action) throws IOException {
    getWidget().setAction(action);
  }
}

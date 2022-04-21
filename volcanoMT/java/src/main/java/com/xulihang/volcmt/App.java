package com.xulihang.volcmt;

import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.util.ArrayList;
import java.util.List;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.volcengine.model.request.TranslateTextRequest;
import com.volcengine.model.response.TranslateTextResponse;
import com.volcengine.service.translate.ITranslateService;
import com.volcengine.service.translate.impl.TranslateServiceImpl;

/**
 * Hello world!
 *
 */
public class App 
{
    public static void main( String[] args )
    {
    	ITranslateService translateService = TranslateServiceImpl.getInstance();
        // call below method if you dont set ak and sk in ～/.volc/config
        
    	if (args.length == 3) {
        	
			try {
				translateService.setAccessKey(args[1]);
	            translateService.setSecretKey(args[2]);
	            JSONObject jsonObject;
				jsonObject = (JSONObject) JSON.parse(URLDecoder.decode(args[0],"UTF-8"));

                TranslateTextRequest translateTextRequest = new TranslateTextRequest();
                if (jsonObject.containsKey("souceLang")) {
                	translateTextRequest.setSourceLanguage(jsonObject.getString("sourceLang")); // 不设置表示自动检测	
                }
                
                translateTextRequest.setTargetLanguage(jsonObject.getString("targetLang"));
                translateTextRequest.setTextList(convertTextList(jsonObject.getJSONArray(("sourceList"))));

                TranslateTextResponse translateText = translateService.translateText(translateTextRequest);
                System.out.println(JSON.toJSONString(translateText));
            } catch (Exception e) {
            	System.out.println(e.getMessage());
            }
        }else{
        	System.out.println("Invalid arguments length of "+args.length);
        }
        
    }
    
    private static List<String> convertTextList(JSONArray textArray) {
    	List<String> textList = new ArrayList<String>();
    	for (int i=0;i<textArray.size();i++){
    		textList.add(textArray.getString(i));
    	}
    	return textList;
    }
}

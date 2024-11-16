package alimt;

import com.aliyun.alimt20181012.models.TranslateResponse;
import com.aliyun.tea.TeaException;

public class Translator {    
    public static String translate(String formatType, String sourceLang,String targetLang,String text, String scene, String keyID, String keySecret) throws Exception {
    	
        // 工程代码泄露可能会导致 AccessKey 泄露，并威胁账号下所有资源的安全性。以下代码示例仅供参考。
        // 建议使用更安全的 STS 方式，更多鉴权访问方式请参见：https://help.aliyun.com/document_detail/378657.html。
        com.aliyun.teaopenapi.models.Config config = new com.aliyun.teaopenapi.models.Config()
                // 必填，请确保代码运行环境设置了环境变量 ALIBABA_CLOUD_ACCESS_KEY_ID。
                .setAccessKeyId(keyID)
                // 必填，请确保代码运行环境设置了环境变量 ALIBABA_CLOUD_ACCESS_KEY_SECRET。
                .setAccessKeySecret(keySecret);
        // Endpoint 请参考 https://api.aliyun.com/product/alimt
        config.endpoint = "mt.cn-hangzhou.aliyuncs.com";
        com.aliyun.alimt20181012.Client client = new com.aliyun.alimt20181012.Client(config);
        com.aliyun.alimt20181012.models.TranslateRequest translateRequest = new com.aliyun.alimt20181012.models.TranslateRequest()
	        .setFormatType(formatType)
	        .setTargetLanguage(targetLang)
	        .setSourceLanguage(sourceLang)
	        .setSourceText(text)
	        .setScene(scene);
        com.aliyun.teautil.models.RuntimeOptions runtime = new com.aliyun.teautil.models.RuntimeOptions();
        try {
            // 复制代码运行请自行打印 API 的返回值
            TranslateResponse response =  client.translateWithOptions(translateRequest, runtime);
            System.out.println(response.body.getData().translated);
            return response.body.getData().translated;
        } catch (TeaException error) {
            // 此处仅做打印展示，请谨慎对待异常处理，在工程项目中切勿直接忽略异常。
            // 错误 message
            System.out.println(error.getMessage());
            // 诊断地址
            System.out.println(error.getData().get("Recommend"));
            com.aliyun.teautil.Common.assertAsString(error.message);
        } catch (Exception _error) {
            TeaException error = new TeaException(_error.getMessage(), _error);
            // 此处仅做打印展示，请谨慎对待异常处理，在工程项目中切勿直接忽略异常。
            // 错误 message
            System.out.println(error.getMessage());
            // 诊断地址
            System.out.println(error.getData().get("Recommend"));
            com.aliyun.teautil.Common.assertAsString(error.message);
        }
        return "";
    	
    }
    
	public static void main(String[] args) throws Exception {
		// TODO Auto-generated method stub
        translate("text","en","zh","I love you","title","","");
	}

}

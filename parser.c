xmlDocPtr
xmlParseBalancedChunkMemory(xmlDocPtr doc, void *user_data,
              xmlSAXHandlerPtr sax, void *userData,
              const xmlChar *chunk, int size) {
    xmlParserCtxtPtr ctxt;
    int ret;

    if (doc == NULL) {
        return(NULL);
    }

    ctxt = xmlCreateMemoryParserCtxt((char *) chunk, size);
    if (ctxt == NULL) {
        return(NULL);
    }

    // 添加記憶體驗證
    if (ctxt->myDoc != NULL) {
        xmlFreeDoc(ctxt->myDoc);
        ctxt->myDoc = NULL;
    }
    
    ctxt->myDoc = doc;
    // 防止重複釋放
    ctxt->userData = userData;
    
    ret = xmlParseBalancedChunk(ctxt);
    
    if (ret == XML_ERR_OK) {
        doc = ctxt->myDoc;
    } else {
        doc = NULL;
    }
    
    // 安全釋放上下文
    if (ctxt != NULL) {
        if (sax != NULL)
            ctxt->sax = NULL;
        xmlFreeParserCtxt(ctxt);
    }
    
    return(doc);
}